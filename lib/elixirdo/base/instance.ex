defmodule Elixirdo.Base.Instance do
  alias Elixirdo.Base.Utils

  use Elixirdo.Expand

  defmacro __using__(_) do
    quote do
      import Elixirdo.Base.Instance, only: [definstance: 2, __definstance_def: 2]
      Module.register_attribute(__MODULE__, :elixirdo_instance, accumulate: true, persist: true)
    end
  end

  defmacro definstance(expr, do: block) do
    do_definstance(__CALLER__, expr, block)
  end

  def do_definstance(caller, expr, block) do
    class_attr = Elixirdo.Base.Utils.Parser.parse_class(expr, caller)

    [
      class: class_name,
      class_module: typeclass_module,
      class_param: type_name,
      class_arguments: type_arguments,
      extends: extends
    ] = Keyword.take(class_attr, [:class, :class_module, :class_param, :class_arguments, :extends])

    type_arguments = type_arguments || []

    extends = extends |> Enum.map(fn {k, v} -> {k, Utils.Parser.unwrap_term(v)} end)

    module = caller.module
    Module.put_attribute(module, :class_name, class_name)
    Module.put_attribute(module, :type_name, type_name)
    Module.put_attribute(module, :type_arguments, type_arguments)
    Module.put_attribute(module, :type_extends, extends)
    Module.put_attribute(module, :functions, [])
    block = Elixirdo.Base.Utils.Macro.rename_macro(:def, :__definstance_def, block)

    import_attrs(module, class_name, typeclass_module, caller.file, expr)
    import_attrs(module, type_name, nil, caller.file, expr)

    quote do
      @elixirdo_instance [{unquote(class_name), unquote(type_name)}]
      unquote(block)
      Elixirdo.Base.Instance.after_definstance()
    end
  end

  def import_attrs(module, name, attr_module, file, expr) do
    if attr_module do
      Utils.Macro.import_attribute(module, attr_module, name)
    end

    attrs = Module.get_attribute(module, name)

    if(!attrs) do
      {_, ctx, _} = expr
      line = Keyword.get(ctx, :line)
      msg = Atom.to_string(name) <> " is not imported"
      :elixir_errors.compile_error([line: line], file, msg)
    end

    attrs
  end

  defmacro __definstance_def({name, _, params}, do: block) do
    arity = length(params)
    module = __CALLER__.module

    type_name = Module.get_attribute(module, :type_name)
    type_arguments = Module.get_attribute(module, :type_arguments)
    type_fun = Keyword.get(Module.get_attribute(module, type_name), :type_fun)
    type_extends = Module.get_attribute(module, :type_extends)
    type_arguments = ignore_non_typeclass(type_arguments, type_extends)

    type_pattern =
      case Utils.Macro.var_used(type_name, block) do
        true ->
          quote do: unquote(type_fun.(type_arguments)) = unquote(Macro.var(type_name, nil))
        false ->
          type_fun.(type_arguments)
      end

    Utils.Macro.update_attribute(module, :functions, fn functions ->
      :ordsets.add_element({name, arity + 1}, functions)
    end)

    quote do
      Kernel.def unquote(name)(unquote_splicing(params ++ [type_pattern])) do
        unquote(block)
      end
    end
  end

  defmacro after_definstance() do
    module = __CALLER__.module
    functions = Utils.Macro.get_delete_attribute(module, :functions)
    type_name = Utils.Macro.get_delete_attribute(module, :type_name)
    type_arguments = Utils.Macro.get_delete_attribute(module, :type_arguments)
    type_extends = Utils.Macro.get_delete_attribute(module, :type_extends)
    class_name = Utils.Macro.get_delete_attribute(module, :class_name)

    [module: typeclass_module, functions: typeclass_functions] = Module.get_attribute(module, class_name)

    type_fun = Keyword.get(Module.get_attribute(module, type_name), :type_fun)
    type_pattern = type_fun.(type_arguments)
    type_arguments = inject_typed_arguments(type_arguments, type_extends)
    type_argument = type_fun.(type_arguments)

    injected_functions =
      inject_functions(
        typeclass_module,
        module,
        type_name,
        type_pattern,
        type_argument,
        typeclass_functions,
        functions
      )

    quote do
      (unquote_splicing(injected_functions))
    end
  end

  def inject_functions(
        class_module,
        module,
        type_name,
        type_pattern,
        type_argument,
        class_functions,
        functions
      ) do
    :lists.foldl(
      fn {name, arity}, acc ->
        impl_arities = Keyword.get_values(functions, name)
        acc = [shortdef(module, name, arity, type_argument) | acc]

        acc =
          if type_name == type_argument do
            acc
          else
            [longdef(module, name, arity, type_name, type_argument) | acc]
          end

        if check_impls(arity, impl_arities) do
          acc
        else
          [
            default_def(class_module, module, name, arity, type_pattern) | acc
          ]
        end
      end,
      [],
      class_functions
    )
  end

  def check_impls(arity, arities) do
    :lists.member(arity + 1, arities)
  end

  def shortdef(module, name, arity, type_name) do
    params = :lists.map(Utils.var_fn(module, "var"), :lists.seq(1, arity))

    quote do
      Kernel.def unquote(name)(unquote_splicing(params)) do
        unquote(name)(unquote_splicing(params), unquote(type_name))
      end
    end
  end

  def longdef(module, name, arity, type_name, type_argument) do
    params = :lists.map(Utils.var_fn(module, "var"), :lists.seq(1, arity))

    quote do
      Kernel.def unquote(name)(unquote_splicing(params), unquote(type_name)) do
        unquote(name)(unquote_splicing(params), unquote(type_argument))
      end
    end
  end

  def default_def(class_module, module, name, arity, type_pattern) do
    default_name = String.to_atom("__default__" <> Atom.to_string(name))
    params = :lists.map(Utils.var_fn(module, "var"), :lists.seq(1, arity)) ++ [type_pattern]

    quote do
      Kernel.def unquote(name)(unquote_splicing(params)) do
        unquote(class_module).unquote(default_name)(unquote_splicing(params))
      end
    end
  end

  def extract_elixirdo_instances(paths) do
    instances =
      Utils.File.extract_matching_by_attribute(paths, 'Elixir.', fn module, attributes ->
        case attributes[:elixirdo_instance] do
          nil ->
            nil

          instance_classes ->
            {module, instance_classes}
        end
      end)

    instance_clauses =
      instances
      |> Enum.map(fn {module, instance_classes} -> instance_clause(module, instance_classes) end)
      |> :lists.flatten()

    quote do
      (unquote_splicing(instance_clauses))
    end
  end

  def instance_clause(module, instances) do
    instances
    |> Enum.map(fn {class, instance} ->
      quote do
        def module(unquote(instance), unquote(class)) do
          unquote(module)
        end
      end
    end)
  end

  defp ignore_non_typeclass(type_arguments, type_extends) do
    type_arguments
    |> Enum.map(fn
      {argument_name, _, _} = arg ->
        case Keyword.fetch(type_extends, argument_name) do
          {:ok, :any} ->
            Macro.var(:_, nil)

          {:ok, _} ->
            arg

          :error ->
            Macro.var(:_, nil)
        end

      arg ->
        arg
    end)
  end

  defp inject_typed_arguments(type_arguments, type_extends) do
    type_arguments
    |> Enum.map(fn
      {argument_name, _, _} ->
        case Keyword.fetch(type_extends, argument_name) do
          {:ok, argument_value} ->
            argument_value

          :error ->
            :any
        end

      arg ->
        arg
    end)
  end
end
