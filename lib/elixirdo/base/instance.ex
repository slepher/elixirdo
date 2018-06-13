defmodule Elixirdo.Base.Instance do
  alias Elixirdo.Base.Utils
  use Elixirdo.Expand

  defmacro __using__(_) do
    quote do
      import Elixirdo.Base.Instance, only: [definstance: 2, __definstance_def: 2]
      Module.register_attribute(__MODULE__, :elixirdo_instance, accumulate: true, persist: true)
    end
  end

  defmacro definstance(name, do: block) do
    class_attr = Elixirdo.Base.Utils.parse_class(name, __CALLER__)
    [class: class_name, class_module: typeclass_module, line: line, class_param: type_name, class_arguments: type_arguments, extends: extends] =
      Keyword.take(class_attr, [:class, :class_module, :line, :class_param, :class_arguments, :extends])

    type_arguments = type_arguments || []

    extends = extends |> Enum.map(fn {k, v} -> {k, Utils.parse_type_param(v)} end)

    module = __CALLER__.module
    Module.put_attribute(module, :class_name, class_name)
    Module.put_attribute(module, :type_name, type_name)
    Module.put_attribute(module, :type_arguments, type_arguments)
    Module.put_attribute(module, :type_extends, extends)
    Module.put_attribute(module, :functions, [])
    block = Elixirdo.Base.Utils.rename_macro(:def, :__definstance_def, block)

    if (typeclass_module) do
      Utils.import_attribute(module, typeclass_module, class_name)
    end

    typeclass_attrs = Module.get_attribute(module, class_name)

    if(!typeclass_attrs) do
      title = "definstance " <> (name |> Macro.to_string)
      :erlang.error(RuntimeError.exception("typeclass " <> Atom.to_string(class_name) <> " is not imported in " <> Atom.to_string(module) <> ":" <> Integer.to_string(line) <> " at " <> title))
    end

    quote do
      @elixirdo_instance [{unquote(class_name), unquote(type_name)}]
      unquote(block)
      Elixirdo.Base.Instance.after_definstance()
    end
  end

  defmacro after_definstance() do
    module = __CALLER__.module
    functions = Utils.get_delete_attribute(module, :functions)
    type_name = Utils.get_delete_attribute(module, :type_name)
    type_arguments = Utils.get_delete_attribute(module, :type_arguments)
    type_extends = Utils.get_delete_attribute(module, :type_extends)
    class_name = Utils.get_delete_attribute(module, :class_name)

    [module: typeclass_module, functions: typeclass_functions] = Module.get_attribute(module, class_name)

    elixirdo_type_funs = Module.get_attribute(module, :elixirdo_type_fun) || []

    type_pattern = build_type_pattern(type_name, type_arguments, elixirdo_type_funs)
    type_arguments = inject_typed_arguments(type_arguments, type_extends)
    type_argument = build_type_pattern(type_name, type_arguments, elixirdo_type_funs)

    result =
      quote do
        (unquote_splicing(
           inject_functions(
             typeclass_module,
             module,
             type_name,
             type_pattern,
             type_argument,
             typeclass_functions,
             functions
           )
         ))
      end

    result |> Macro.to_string() |> IO.puts()
    result
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

  defmacro __definstance_def({name, _, params}, do: block) do
    arity = length(params)
    module = __CALLER__.module

    type_name = Module.get_attribute(module, :type_name)
    type_arguments = Module.get_attribute(module, :type_arguments)
    elixirdo_type_funs = Module.get_attribute(module, :elixirdo_type_fun) || []

    type_pattern = build_type_pattern(type_name, type_arguments, elixirdo_type_funs)

    Utils.update_attribute(module, :functions, fn functions ->
      :ordsets.add_element({name, arity + 1}, functions)
    end)

    quote do
      Kernel.def unquote(name)(unquote_splicing(params ++ [type_pattern])) do
        unquote(block)
      end
    end
  end

  def extract_elixirdo_instances(paths) do
    instances =
      Utils.extract_matching_by_attribute(paths, 'Elixir.', fn module, attributes ->
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

  defp inject_typed_arguments(type_arguments, type_extends) do
    type_arguments
    |> Enum.map(fn
      {argument_name, _, _} = arg ->
        case Keyword.fetch(type_extends, argument_name) do
          {:ok, argument_value} ->
            argument_value

          :error ->
            arg
        end

      arg ->
        arg
    end)
  end

  defp build_type_pattern(type_name, type_arguments, elixirdo_type_funs) do
    case Keyword.fetch(elixirdo_type_funs, type_name) do
      {:ok, elixirdo_type_fun} ->
        elixirdo_type_fun.(type_arguments)

      :error ->
        nil
    end
  end
end
