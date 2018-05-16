defmodule Elixirdo.Base.Type do
  alias Elixirdo.Base.Utils

  require Record
  Record.defrecord :cache, Record.extract(:cache, from_lib: "hipe/cerl/erl_types.erl")

  defstruct [:module, :name, :details]

  defmacro __using__(_) do
    quote do
      import Elixirdo.Base.Type, only: [deftype: 1]
      Module.register_attribute(__MODULE__, :elixirdo_type, accumulate: false, persist: true)
    end
  end

  defmacro deftype([{name, arity}]) do
    quote do
      @elixirdo_type {unquote(name), unquote(arity), true}
    end
  end

  defmacro deftype({:::, _, [{name, _, args}, _type_defs]} = spec) do
    arity = length(args)

    quote do
      @type unquote(spec)
      @elixirdo_type {unquote(name), unquote(arity), false}
      unquote_splicing([do_deftype(name, __CALLER__, spec)])
    end
  end

  def do_deftype(name, caller, _spec) do
    module = caller.module

    quote do
      def type() do
        %Elixirdo.Base.Type{module: unquote(module), name: unquote(name)}
      end
    end
  end

  def extract_elixirdo_types(paths) do

    rec_table = :ets.new(:rec_table, [:protected])
    mfas =
      Utils.extract_matching_by_attribute(paths, 'Elixir.', fn module, attributes ->
        case attributes[:elixirdo_type] do
          nil ->
            nil

          [{type, arity, inner_type}] ->
            {module, type, arity, inner_type}
        end
      end)
    {_, _, expanded_types} =
      :lists.foldl(
        fn {module, name, arity, inner_type}, {modules_loaded, types, acc} ->
        case inner_type do
            false ->
              case load_types_remote(module, name, arity, modules_loaded, types, rec_table) do
                :error ->
                  {modules_loaded, types, acc}
                {:ok, {type, modules_loaded, types}} ->
                  acc = [{module, name, arity, type} | acc]
                  {modules_loaded, types, acc}
              end
            true ->
              {modules_loaded, types, acc}
            end
        end,
        {:maps.new(), :sets.new(), []},
        mfas
      )

    expanded_types
  end

  def load_types_remote(module, type, arity, modules_loaded, types, rec_table) do
    case preload_types(module, type, arity, modules_loaded, types, rec_table) do
      {:ok, {modules_loaded, types}} ->
        case table_find_form(module, type, arity, rec_table) do
          {:ok, form} ->
            type = t_from_form(form, module, type, arity, types, rec_table)
            {:ok, {type, modules_loaded, types}}
          _ ->
            :error
        end
      :error ->
        :error
    end
  end

  def preload_types(module, type, arity, modules_loaded, types, rec_table) do
    case types_visited(module, modules_loaded, types, rec_table) do
      {:ok, {types_visited, modules_loaded, types}} ->
        case :ordsets.is_element({type, arity}, types_visited) do
          false ->
            case table_find_rec_and_form(module, type, arity, rec_table) do
              {:ok, {rec_map, form}} ->
                types_visited = :ordsets.add_element({module, type, arity}, types_visited)
                modules_loaded = Map.put(modules_loaded, module, types_visited)
                {:ok, preload_form_types(form, module, rec_map, modules_loaded, types, rec_table)}
              :error ->
                :error
              end
          true ->
            {:ok, {modules_loaded, types}}
        end
      :error ->
        :error
    end
  end

  def types_visited(module, modules_loaded, types, rec_table) do
    case Map.fetch(modules_loaded, module) do
      :error ->
        types_visited = :ordsets.new()
        modules_loaded = Map.put(modules_loaded, module, types_visited)
        case types_and_rec_map(module) do
          {:ok, {module_types, rec_map}} ->
            types = :sets.union(types, module_types)
            :ets.insert(rec_table, {module, rec_map})
            {:ok, {types_visited, modules_loaded, types}}
          :error ->
            :error
          end
      {:ok, types_visited} ->
        {:ok, {types_visited, modules_loaded, types}}
    end
  end

  def preload_form_types(form, module, rec_map, modules_loaded, types, rec_table) do
    :ast_traverse.reduce(
      fn
        :pre, node, {modules_loaded, types} ->
          preload_node_types(node, module, rec_map, modules_loaded, types, rec_table)
        _, _, acc ->
          acc
      end,
      {modules_loaded, types},
      form
    )
  end

  def preload_node_types(
        {:remote_type, line, [{:atom, _, remote_module}, {:atom, _, type}, args]},
        module, _rec_map, modules_loaded, types, rec_table) do
    arity = length(args)
    case preload_types(remote_module, type, arity, modules_loaded, types, rec_table) do
      {:ok, val} ->
        val
      :error ->
        Mix.raise("invalid type #{remote_module}:#{type}/#{arity} at #{module}:#{line}")
    end
  end

  def preload_node_types(
        {:user_type, _line, type, args},
        module, rec_map, modules_loaded, types, rec_table) do
    arity = length(args)
    case map_find_form(type, arity, rec_map) do
      {:ok, form} ->
        preload_form_types(form, module, rec_map, modules_loaded, types, rec_table)
      :error ->
        {modules_loaded, types}
    end
  end

  def preload_node_types(_form, _module, _rec_map, modules_loaded, types, _rec_table) do
    {modules_loaded, types}
  end

  def types_and_rec_map(module) do
    case core(module) do
      {:ok, core} ->
        types = exported_types(core)
        case :dialyzer_utils.get_record_and_type_info(core) do
          {:ok, rec_map} ->
            {:ok, {types, rec_map}}
          _ ->
            :error
        end
      _ ->
        :error
    end
  end

  def core(module) do
    case :code.get_object_code(module) do
      {^module, _, beam} ->
        :dialyzer_utils.get_core_from_beam(beam)

      :error ->
        {:error, {:not_loaded, module}}
    end
  end

  def table_find_form(module, type, arity, rec_table) do
    case table_find_rec_and_form(module, type, arity, rec_table) do
      {:ok, {_rec_map, form}} ->
        {:ok, form}
      :error ->
        :error
    end
  end

  def table_find_rec_and_form(module, type, arity, rec_table) do
    case :ets.lookup(rec_table, module) do
      [{^module, rec_map}] ->
        case map_find_form(type, arity, rec_map) do
          {:ok, form} ->
            {:ok, {rec_map, form}}
          :error ->
            :error
        end
      [] ->
        :error
    end
  end

  def map_find_form(type, arity, rec_map) do
    case Map.fetch(rec_map, {:type, type, arity}) do
      {:ok, {{_module, _line, form, _args}, _}} ->
        {:ok, form}
      _ ->
        :error
    end
  end

  def exported_types(core) do
    attrs = :cerl.module_attrs(core)
    exp_types =
      for {l1, l2} <- attrs,
          :cerl.is_literal(l1),
          :cerl.is_literal(l2),
          :cerl.concrete(l1) == :export_type,
          do: :cerl.concrete(l2)

    exp_types = :lists.flatten(exp_types)
    m = :cerl.atom_val(:cerl.module_name(core))
    :sets.from_list(for {f, a} <- exp_types, do: {m, f, a})
  end

  def t_from_form(form, module, type, arity, types, rec_table) do
    cache = :erl_types.cache__new()
    var_table = :erl_types.var_table__new()
    type1 = {:type, {module, type, arity}}
    {type, _cache} =
      :erl_types.t_from_form(form, types, type1, rec_table, var_table, cache)
    type
  end
end
