defmodule Elixirdo.TypeclassRegister do

  require Record

  @behaviour :gen_server


  defmacrop erlconst_SERVER() do
    quote do
      __MODULE__
    end
  end


  @erlrecordfields_state [:behaviour_modules, :typeclasses, :type_aliases, :types, :exported_types, :mod_recs]
  Record.defrecordp :erlrecord_state, :state, [behaviour_modules: :maps.new(), typeclasses: [], type_aliases: [], types: :maps.new(), exported_types: :sets.new(), mod_recs: :dict.new()]

  @erlrecordfields_cache [:types, :mod_recs]
  Record.defrecordp :erlrecord_cache, :cache, [types: :maps.new(), mod_recs: {:mrecs, :dict.new()}]


  def register_application(application) do
    case(:application.get_key(application, :modules)) do
      {:ok, modules} ->
        register_modules(modules)
      :undefined ->
        {:error, :undefined}
    end
  end


  def register_modules(modules) do
    :gen_server.call(erlconst_SERVER(), {:register_modules, modules})
  end


  def types() do
    :gen_server.call(erlconst_SERVER(), :types)
  end


  def typeclasses() do
    :gen_server.call(erlconst_SERVER(), :typeclasses)
  end


  def behaviours() do
    :gen_server.call(erlconst_SERVER(), :behaviours)
  end


  def start_link() do
    :gen_server.start_link({:local, erlconst_SERVER()}, __MODULE__, [], [])
  end


  def init([]) do
    {:ok, erlrecord_state([])}
  end


  def handle_call({:register_modules, modules}, _from, erlrecord_state(behaviour_modules: behaviourModules, typeclasses: var_typeclasses, types: var_types, exported_types: eTypes, mod_recs: modRecs) = state) do
    {nETypes, nModRecs} = :lists.foldl(fn module, {eTypeAcc, modRecAcc} -> update_types_and_rec_map(module, eTypeAcc, modRecAcc) end, {eTypes, modRecs}, modules)
    nTypeclasses = :lists.foldl(fn module, acc ->
      classes = superclasses(module)
      case(classes) do
        [] ->
          acc
        _ ->
          :ordsets.add_element(module, acc)
      end
    end, var_typeclasses, modules)
    {nTypes, nBehaviourModules} = :lists.foldl(fn module, {tIAcc, tBMAcc} ->
      {typeInstanceMap, typeBehaviourModuleMap} = module_type_info(module, nTypeclasses, nETypes, nModRecs)
      {merge_type_instance(tIAcc, typeInstanceMap), :maps.merge(tBMAcc, typeBehaviourModuleMap)}
    end, {var_types, behaviourModules}, modules)
    nNTypes = :maps.map(fn
      type, :undefined ->
        [tuple: [{:atom, type}, :any]]
      _type, patterns ->
        patterns
    end, nTypes)
    do_load_module(nNTypes, nTypeclasses, nBehaviourModules)
    {:reply, :ok, erlrecord_state(state, behaviour_modules: nBehaviourModules, typeclasses: nTypeclasses, types: nNTypes, exported_types: nETypes, mod_recs: nModRecs)}
  end

  def handle_call(:types, _from, erlrecord_state(types: var_types) = state) do
    {:reply, {:ok, var_types}, state}
  end

  def handle_call(:typeclasses, _from, erlrecord_state(typeclasses: var_typeclasses) = state) do
    {:reply, {:ok, var_typeclasses}, state}
  end

  def handle_call(:behaviours, _from, erlrecord_state(behaviour_modules: var_behaviours) = state) do
    {:reply, {:ok, var_behaviours}, state}
  end

  def handle_call(_request, _from, state) do
    reply = :ok
    {:reply, reply, state}
  end


  def handle_cast(_msg, state) do
    {:noreply, state}
  end


  def handle_info(_info, state) do
    {:noreply, state}
  end


  def terminate(_reason, _state) do
    :ok
  end


  def code_change(_oldVsn, state, _extra) do
    {:ok, state}
  end


  def type_with_remote(module, type, args, modules) do
    {exportedTypes, tRecDict} = :lists.foldl(fn mod, {typeAcc, recAcc} -> update_types_and_rec_map(mod, typeAcc, recAcc) end, {:sets.new(), :dict.new()}, [module | modules])
    type_with_remote(module, type, args, exportedTypes, tRecDict)
  end


  defp type_with_remote(module, type, args, exportedTypes, tRecMap) do
    recMap = case(:dict.find(module, tRecMap)) do
      {:ok, val} ->
        val
      :error ->
        %{}
    end
    type0 = {:type, type, args}
    type1 = {:type, {module, type, args}}
    case(:maps.find(type0, recMap)) do
      {:ok, {{^module, _fileLine, typeForm, _argNames}, _}} ->
        cache = erlrecord_cache(mod_recs: {:mrecs, tRecMap})
        {cType, _nCache} = :erl_types_R20.t_from_form(typeForm, exportedTypes, type1, :undefined, %{}, cache)
        {:ok, cType}
      :error ->
        {:error, :undefined_type}
    end
  end


  def type_to_patterns({:c, :tuple, tuples, _}) do
    tupleLists = :lists.foldl(fn tupleValue, accs ->
      patterns = type_to_patterns(tupleValue)
      case(accs) do
        [] ->
          :lists.map(fn pattern -> [pattern] end, patterns)
        ^accs ->
          for(accValue <- accs, pattern <- patterns, into: [], do: [pattern | accValue])
      end
    end, [], tuples)
    :lists.map(fn tupleList -> {:tuple, :lists.reverse(tupleList)} end, tupleLists)
  end

  def type_to_patterns({:c, :function, _function, _}) do
    [guard: :is_function]
  end

  def type_to_patterns({:c, :atom, atoms, _}) do
    :lists.map(fn atom -> {:atom, atom} end, atoms)
  end

  def type_to_patterns({:c, :tuple_set, [{_n, sets}], _}) do
    :lists.foldl(fn item, acc -> type_to_patterns(item) ++ acc end, [], sets)
  end

  def type_to_patterns({:c, :union, unions, _}) do
    :lists.foldl(fn item, acc -> type_to_patterns(item) ++ acc end, [], unions)
  end

  def type_to_patterns({:c, :list, _, _}) do
    [guard: :is_list]
  end

  def type_to_patterns({:c, :map, _, _}) do
    [guard: :is_map]
  end

  def type_to_patterns({:c, :binary, _, _}) do
    [guard: :is_binary]
  end

  def type_to_patterns({:c, :var, _, _}) do
    [:any]
  end

  def type_to_patterns(:any) do
    [:any]
  end

  def type_to_patterns(:none) do
    []
  end

  def type_to_patterns({:c, _type, _body, _qualifier}) do
    []
  end


  def pattern_to_clause(line, type, pattern) do
    {nPattern, guards, _} = pattern_to_pattern_gurads(line, pattern, [], 1)
    guardTest = case(guards) do
      [] ->
        []
      _ ->
        [guards]
    end
    {:clause, line, [nPattern], guardTest, [{:atom, line, type}]}
  end


  defp pattern_to_pattern_gurads(line, {:tuple, tuples}, guards, offset) do
    {tupleList, nGuards, nOffset} = :lists.foldl(fn element, {patternAcc, guardAcc, offsetAcc} ->
      {pattern, nGuardAcc, nOffsetAcc} = pattern_to_pattern_gurads(line, element, guardAcc, offsetAcc)
      {[pattern | patternAcc], nGuardAcc, nOffsetAcc}
    end, {[], guards, offset}, tuples)
    {{:tuple, line, :lists.reverse(tupleList)}, nGuards, nOffset}
  end

  defp pattern_to_pattern_gurads(line, :any, guards, offset) do
    {{:var, line, :_}, guards, offset}
  end

  defp pattern_to_pattern_gurads(line, {:atom, atom}, guards, offset) do
    {{:atom, line, atom}, guards, offset}
  end

  defp pattern_to_pattern_gurads(line, {:guard, guard}, guards, offset) do
    argName = :erlang.list_to_atom('Args' ++ :erlang.integer_to_list(offset))
    {{:var, line, argName}, [{:call, line, {:atom, line, guard}, [{:var, line, argName}]} | guards], offset + 1}
  end


  defp module_type_info(module, var_typeclasses, eTypes, modRecs) do
    typeAttrs = types(module)
    var_behaviours = behaviours(module)
    typeInstanceMap = :lists.foldl(fn
      {type, usedTypes}, acc1 ->
        patterns = type_patterns(module, usedTypes, eTypes, modRecs)
        :maps.put(type, patterns, acc1)
      (type, acc1) when is_atom(type) ->
        case(:maps.find(type, acc1)) do
          {:ok, _patterns} ->
            acc1
          :error ->
            :maps.put(type, :undefined, acc1)
        end
    end, :maps.new(), typeAttrs)
    var_types = :maps.keys(typeInstanceMap)
    typeBehaviourMap = :lists.foldl(fn type, acc1 -> :lists.foldl(fn behaviour, acc2 -> case(:ordsets.is_element(behaviour, var_typeclasses)) do
      true ->
        :maps.put({type, behaviour}, module, acc2)
      false ->
        acc2
    end end, acc1, var_behaviours) end, :maps.new(), var_types)
    {typeInstanceMap, typeBehaviourMap}
  end


  defp merge_type_instance(typeInstanceMap, nTypeInstanceMap) do
    :maps.fold(fn type, pattern, acc -> case(:maps.find(type, acc)) do
      {:ok, :undefined} ->
        :maps.put(type, pattern, acc)
      {:ok, _} ->
        acc
      :error ->
        :maps.put(type, pattern, acc)
    end end, typeInstanceMap, nTypeInstanceMap)
  end


  defp superclasses(module) do
    :ast_traverse.module_attributes(:superclass, module)
  end


  defp types(module) do
    :lists.flatten(:ast_traverse.module_attributes(:erlando_type, module))
  end


  defp behaviours(module) do
    :lists.flatten(:ast_traverse.module_attributes(:behaviour, module))
  end


  defp do_load_module(var_types, var_typeclasses, behaviourModules) do
    typeclassModule = {:attribute, 0, :module, :typeclass}
    export = {:attribute, 0, :export, [module: 2, is_typeclass: 1, type: 1]}
    typesFun = generate_type(var_types)
    isTypeClass = generate_is_typeclass(var_typeclasses)
    module = generate_module(behaviourModules)
    {:ok, mod, bin} = :compile.forms([typeclassModule, export, typesFun, isTypeClass, module])
    :code.load_binary(mod, [], bin)
  end


  defp generate_type(var_types) do
    clauses = :maps.fold(fn type, patterns, acc ->
      nPatterns = case(patterns) do
        :undefined ->
          [tuple: [{:atom, type}, :any]]
        _ ->
          patterns
      end
      :lists.map(fn pattern -> pattern_to_clause(0, type, pattern) end, nPatterns) ++ acc
    end, [], var_types)
    lastClause = {:clause, 0, [{:var, 0, :_}], [], [{:atom, 0, :undefined}]}
    {:function, 0, :type, 1, clauses ++ [lastClause]}
  end


  defp generate_is_typeclass(var_typeclasses) do
    clauses = :lists.foldl(fn typeclass, acc -> [is_typeclass_clause(0, typeclass) | acc] end, [], var_typeclasses)
    lastClause = {:clause, 0, [{:var, 0, :_A}], [], [{:atom, 0, false}]}
    {:function, 0, :is_typeclass, 1, :lists.reverse([lastClause | clauses])}
  end


  defp generate_module(behaviourModules) do
    clauses = :maps.fold(fn {type, behaviour}, module, acc -> [module_clause(0, type, behaviour, module) | acc] end, [], behaviourModules)
    lastClause = {:clause, 0, [{:var, 0, :A}, {:var, 0, :B}], [], [{:call, 0, {:atom, 0, :exit}, [{:tuple, 0, [{:atom, 0, :unregisted_module}, {:tuple, 0, [{:var, 0, :A}, {:var, 0, :B}]}]}]}]}
    {:function, 0, :module, 2, :lists.reverse([lastClause | clauses])}
  end


  defp is_typeclass_clause(line, typeclass) do
    {:clause, line, [{:atom, line, typeclass}], [], [{:atom, line, true}]}
  end


  defp module_clause(line, type, behaviour, module) do
    {:clause, 1, [{:atom, line, type}, {:atom, line, behaviour}], [], [{:atom, line, module}]}
  end


  defp type_patterns(module, var_types, eTypes, modRecs) do
    :lists.foldl(fn {type, arity}, acc -> case(type_with_remote(module, type, arity, eTypes, modRecs)) do
      {:ok, cType} ->
        patterns = type_to_patterns(cType)
        :lists.usort(patterns ++ acc)
      {:error, _} ->
        acc
    end end, [], var_types)
  end


  defp core(module) do
    case(:code.get_object_code(module)) do
      {^module, _, beam} ->
        :dialyzer_utils_R20.get_core_from_beam(beam)
      :error ->
        {:error, {:not_loaded, module}}
    end
  end


  defp update_types_and_rec_map(module, var_types, mRecDict) do
    case(core(module)) do
      {:ok, var_core} ->
        case(rec_map(var_core)) do
          {:ok, recMap} ->
            mTypes = exported_types(var_core)
            nETypeAcc = :sets.union(mTypes, var_types)
            nMRecDict = case(:maps.size(recMap)) do
              0 ->
                mRecDict
              _ ->
                :dict.store(module, recMap, mRecDict)
            end
            {nETypeAcc, nMRecDict}
          {:error, _reason} ->
            {var_types, mRecDict}
        end
      {:error, _reason} ->
        {var_types, mRecDict}
    end
  end


  defp exported_types(var_core) do
    attrs = :cerl.module_attrs(var_core)
    expTypes1 = for({l1, l2} <- attrs, :cerl.is_literal(l1), :cerl.is_literal(l2), :cerl.concrete(l1) === :export_type, into: [], do: :cerl.concrete(l2))
    expTypes2 = :lists.flatten(expTypes1)
    m = :cerl.atom_val(:cerl.module_name(var_core))
    :sets.from_list(for({f, a} <- expTypes2, into: [], do: {m, f, a}))
  end


  defp rec_map(var_core) do
    :dialyzer_utils_R20.get_record_and_type_info(var_core)
  end

end
