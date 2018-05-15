defmodule Elixirdo.Base.Type do
  alias Elixirdo.Base.Utils

  require Record
  Record.defrecord(:cache, types: :maps.new(), mod_recs: {:mrecs, :dict.new()})

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
    mfas =
      Utils.extract_matching_by_attribute(paths, 'Elixir.', fn module, attributes ->
        case attributes[:elixirdo_type] do
          nil ->
            nil

          [{type, arity, inner_type}] ->
            {module, type, arity, inner_type}
        end
      end)
    {_, _, _, _, expanded_types} =
      :lists.foldl(
        fn {module, name, arity, inner_type},
           {types, rec_dict, modules_loaded, types_visited, acc} ->
          case inner_type do
            false ->
              case load_types_remote(
                     module,
                     name,
                     arity,
                     rec_dict,
                     types,
                     modules_loaded,
                     types_visited
                   ) do
                :error ->
                  {types, rec_dict, modules_loaded, types_visited, acc}
                {:ok, {type, types, rec_dict, modules_loaded, types_visited}} ->
                  acc = [{module, name, arity, type} | acc]
                  {types, rec_dict, modules_loaded, types_visited, acc}
              end
            true ->
              {types, rec_dict, modules_loaded, types_visited, acc}
          end
        end,
        {:sets.new(), :dict.new(), :sets.new(), :sets.new(), []},
        mfas
      )

    expanded_types
  end

  def load_types_remote(module, type, arity, rec_dict, types, modules_loaded, types_visited) do
    {rec_dict, types, modules_loaded, types_visited} =
      remote_types(module, type, arity, rec_dict, types, modules_loaded, types_visited)

    case find_form_by_mfa(module, type, arity, rec_dict) do
      {:ok, form} ->
        cache_rec = cache(mod_recs: {:mrecs, rec_dict})
        type1 = {:type, {module, type, arity}}

        {type, _cache_rec} =
          :erl_types.t_from_form(form, types, type1, :undefined, %{}, cache_rec)

        {:ok, {type, types, rec_dict, modules_loaded, types_visited}}

      _ ->
        :error
    end
  end

  def update_types_and_rec_dict(module, core, types, rec_dict) do
    core_types = exported_types(core)
    types = :sets.union(types, core_types)

    case :dialyzer_utils.get_record_and_type_info(core) do
      {:ok, core_rec_dict} ->
        rec_dict =
          case :maps.size(core_rec_dict) do
            0 ->
              rec_dict

            _ ->
              :dict.store(module, core_rec_dict, rec_dict)
          end

        {types, rec_dict}

      {:error, _} ->
        {types, rec_dict}
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

  def find_form_by_mfa(module, type, arity, rec_dict) do
    case :dict.find(module, rec_dict) do
      {:ok, rec_map} ->
        find_form(type, arity, rec_map)

      :error ->
        :error
    end
  end

  def find_form(type, arity, rec_map) do
    case :maps.find({:type, type, arity}, rec_map) do
      {:ok, {{_module, _line, form, _args}, _}} ->
        {:ok, form}

      _ ->
        :error
    end
  end

  def remote_types(module, type, arity, rec_dict, types, modules_loaded, types_visited) do
    case :sets.is_element(module, modules_loaded) do
      false ->
        modules_loaded = :sets.add_element(module, modules_loaded)

        case load_module_types(module) do
          {:ok, {module_types, module_rec_map}} ->
            types = :sets.union(types, module_types)
            rec_dict = :dict.store(module, module_rec_map, rec_dict)

            case find_form(type, arity, module_rec_map) do
              {:ok, form} ->
                remote_types(form, module_rec_map, rec_dict, types, modules_loaded, types_visited)

              :error ->
                {rec_dict, types, modules_loaded, types_visited}
            end

          :error ->
            {rec_dict, types, modules_loaded, types_visited}
        end

      true ->
        case :sets.is_element({module, type, arity}, types_visited) do
          false ->
            types_visited = :sets.add_element({module, type, arity}, types_visited)
            case :dict.find(module, rec_dict) do
              {:ok, rec_map} ->
                case find_form(type, arity, rec_map) do
                  {:ok, form} ->
                    remote_types(form, rec_map, rec_dict, types, modules_loaded, types_visited)
                  :error ->
                    {rec_dict, types, modules_loaded, types_visited}
                end
              :error ->
                {rec_dict, types, modules_loaded, types_visited}
            end
          true ->
            {rec_dict, types, modules_loaded, types_visited}
        end
    end
  end

  def remote_types(form, rec_map, rec_dict, types, modules_loaded, types_visited) do
    :ast_traverse.reduce(
      fn
        :pre, node, {rec_dict, types, modules_loaded, types_visited} ->
          reduce_action(node, rec_map, rec_dict, types, modules_loaded, types_visited)
        _, _, acc ->
          acc
      end,
      {rec_dict, types, modules_loaded, types_visited},
      form
    )
  end

  def reduce_action(
        {:remote_type, _line, [{:atom, _, module}, {:atom, _, type}, args]},
        _rec_map,
        rec_dict,
        types,
        modules_loaded,
        types_visited
      ) do
    arity = :erlang.length(args)
    remote_types(module, type, arity, rec_dict, types, modules_loaded, types_visited)
  end

  def reduce_action(
        {:user_type, _line, type, args},
        rec_map,
        rec_dict,
        types,
        modules_loaded,
        types_visited
      ) do
    arity = :erlang.length(args)
    case find_form(type, arity, rec_map) do
      {:ok, form} ->
        remote_types(form, rec_map, rec_dict, types, modules_loaded, types_visited)
      :error ->
        {rec_dict, types, modules_loaded, types_visited}
    end
  end

  def reduce_action(_form, _rec_map, rec_dict, types, modules_loaded, types_visited) do
    {rec_dict, types, modules_loaded, types_visited}
  end

  def load_module_types(module) do
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
end
