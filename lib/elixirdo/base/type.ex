defmodule Elixirdo.Base.Type do
  alias Elixirdo.Base.Utils

  defstruct [:module, :name, :details]

  defmacro __using__(_) do
    quote do
      import Elixirdo.Base.Type, only: [deftype: 1, deftype: 2, import_type: 1]
      Module.register_attribute(__MODULE__, :elixirdo_type, accumulate: true, persist: true)
    end
  end

  defmacro deftype([{name, arity}]) do
    quote do
      @elixirdo_type {unquote(name), unquote(arity), true}
    end
  end

  defmacro deftype({:::, _, [{name, _, _args}, _type_defs]} = spec) do
    module = __CALLER__.module
    do_deftype(module, spec, as: name)
  end

  defmacro deftype(spec, opts) do
    module = __CALLER__.module
    do_deftype(module, spec, opts)
  end

  def do_deftype(module, {:::, ctx1, [{name, ctx2, args}, type_defs]}, opts) do
    {type_defs, typeclasses} = extract_typeclass(module, args, type_defs)
    spec = {:::, ctx1, [{name, ctx2, args}, type_defs]}
    as = Keyword.get(opts, :as, name)
    exported = Keyword.get(opts, :export, true)
    arity = length(args)

    if exported do
      elixirdo_types = Module.get_attribute(module, :elixirdo_type) || []
      Module.put_attribute(module, :elixirdo_type, [as| elixirdo_types])
      elixirdo_type_fun_in_fun = type_fun(as, args, typeclasses, true)
      elixirdo_type_fun_in_attr = type_fun(as, args, typeclasses, false)
      type_attributes = [name: as, type_name: name, arity: arity]
      type_attribute_in_attr = type_attributes ++ [type_fun: elixirdo_type_fun_in_attr]
      type_attribute_in_fun = type_attributes ++ [type_fun: elixirdo_type_fun_in_fun]
      exported_attribute = Utils.export_attribute(module, as, type_attribute_in_attr, type_attribute_in_fun)
      quote do
        @type unquote(spec)
        unquote(exported_attribute)
      end
    else
      quote do: @type unquote(spec)
    end
  end

  defmacro import_type({{:., _, [from_module, type]}, _, _}) do
    module = __CALLER__.module
    from_module = Macro.expand(from_module, __CALLER__)
    Utils.import_attribute(module, from_module, type)
    nil
  end

  def type_fun(type_name, args, typeclasses, quoted) do
    args_offsets =
      case args do
        [] -> []
        _  -> Enum.to_list(1..length(args))
      end

    typeclass_arguments_offsets =
      args_offsets
      |> Enum.filter(fn n ->
        type_arg_name = Utils.parse_type_param(:lists.nth(n, args))
        Enum.member?(typeclasses, type_arg_name)
      end)

    if quoted do
      type_fun_in_fun(type_name, typeclass_arguments_offsets)
    else
      type_fun_in_attr(type_name, typeclass_arguments_offsets)
    end
  end

  def type_fun_in_fun(type_name, typeclass_arguments_offsets) do
    quote do
      fn type_args ->
        type_name = unquote(type_name)
        args = Enum.map(unquote(typeclass_arguments_offsets), fn n -> :lists.nth(n, type_args) end)
        case args do
          [] -> quote do: unquote(type_name)
          _  -> quote do: {unquote(type_name), unquote_splicing(args)}
        end
      end
    end
  end

  def type_fun_in_attr(type_name, typeclass_arguments_offsets) do
    fn type_args ->
      args = Enum.map(typeclass_arguments_offsets, fn n -> :lists.nth(n, type_args) end)
      case args do
        [] -> quote do: unquote(type_name)
        _  -> quote do: {unquote(type_name), unquote_splicing(args)}
      end
    end
  end

  def extract_typeclass(module, args, type_defs) do
    arg_names = args |> Enum.map(fn {var, _ctx, _} -> var end)

    Macro.traverse(
      type_defs,
      [],
      fn
        {type, _ctx, arguments} = ast, acc when is_list(arguments) ->
          case Enum.member?(arg_names, type) do
            true ->
              type_var = Macro.var(type, module)

              ast =
                quote do
                  Elixirdo.Base.Typeclass.class(unquote(type_var), unquote(arguments))
                end

              {ast, [type | acc]}

            false ->
              {ast, acc}
          end

        ast, acc ->
          {ast, acc}
      end,
      fn ast, acc ->
        {ast, acc}
      end
    )
  end

  def extract_elixirdo_types(paths) do
    cache = :type_expansion.cache()

    mfas =
      Utils.extract_matching_by_attribute(paths, 'Elixir.', fn module, attributes ->
        case attributes[:elixirdo_type] do
          nil ->
            nil

          types ->
            types
            |> Enum.map(fn name -> {module, name} end)
        end
      end)

    IO.inspect mfas

    expanded_types =
      :lists.foldl(
        fn {module, name}, acc ->
          [type_name: type_name, arity: arity] = Keyword.take(:erlang.apply(module, name, []), [:type_name, :arity])
          case :type_expansion.expand(module, type_name, arity, cache) do
            :error ->
              acc

            {:ok, type} ->
              acc = [{module, name, type} | acc]
              acc
          end
        end,
        [],
        :lists.flatten(mfas)
      )

    errors = :type_expansion.cache_errors(cache)
    :type_expansion.finalize_cache(cache)

    format_errors(errors)

    quote do
      (unquote_splicing(types_to_clauses(expanded_types)))
    end
  end

  def types_to_clauses(expanded_types) do
    expanded_types
    |> Enum.map(fn {module, name, type} ->
      to_clauses(module, name, type)
    end)
    |> :lists.flatten()
  end

  def to_clauses(module, type_name, type) do
    clauses = :type_formal_trans.to_clauses(type)

    clauses
    |> Enum.map(fn {type_var, type_guards} ->
      var = format_var(module, type_var)
      guards = format_guards(module, type_guards)

      if guards do
        quote do
          def type(unquote(var)) when unquote(guards) do
            unquote(type_name)
          end
        end
      else
        quote do
          def type(unquote(var)) do
            unquote(type_name)
          end
        end
      end
    end)
  end

  def format_var(module, {:var, 0}) do
    Macro.var(:_, module)
  end

  def format_var(module, {:var, n}) do
    var(module, n, "var")
  end

  def format_var(module, {:tuple, tuples}) do
    formatted_tuples = tuples |> Enum.map(fn tuple -> format_var(module, tuple) end)

    quote do
      {unquote_splicing(formatted_tuples)}
    end
  end

  def format_var(module, {:map, pairs}) do
    {struct_module, pairs} = Keyword.pop_first(pairs, :__struct__)

    pairs =
      pairs
      |> Enum.map(fn {key, value} ->
        {format_var(module, key), format_var(module, value)}
      end)

    if struct_module do
      quote do
        %unquote(struct_module){unquote_splicing(pairs)}
      end
    else
      quote do
        %{unquote_splicing(pairs)}
      end
    end
  end

  def format_var(_module, var) when is_atom(var) do
    var
  end

  def format_guards(_module, []) do
    nil
  end

  def format_guards(module, [guard | guards]) do
    formatted_guard = format_guard(module, guard)
    formatted_guards = format_guards(module, guards)

    if formatted_guards do
      quote do
        unquote(formatted_guard) and unquote(formatted_guards)
      end
    else
      formatted_guard
    end
  end

  def format_guard(module, {guard_function, n}) do
    var_name = var(module, n, "var")

    quote do
      unquote(guard_function)(unquote(var_name))
    end
  end

  def var(module, n, prefix) do
    var_name = prefix <> "_" <> Integer.to_string(n)
    Macro.var(String.to_atom(var_name), module)
  end

  def format_errors(errors) do
    case errors do
      [] ->
        :ok

      _ ->
        Enum.map(errors, fn
          {{module, type, arity}, at_module, line} ->
            Mix.shell().error(
              "type not defined #{module}:#{type}/#{arity} at #{at_module}:#{line}"
            )

          {module, at_module, line} ->
            Mix.shell().error("module could not loaded #{module} at #{at_module}:#{line}")
        end)

        Mix.raise("compile failed")
    end
  end
end
