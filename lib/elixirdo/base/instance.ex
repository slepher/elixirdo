defmodule Elixirdo.Base.Instance do
  alias Elixirdo.Base.Utils

  defmacro __using__(_) do
    quote do
      import Elixirdo.Base.Instance, only: [definstance: 2, __definstance_def: 2]
    end
  end

  defmacro definstance(name, do: block) do
    class_attr = Elixirdo.Base.Utils.parse_class(name)
    [class: class_name, class_param: class_param, extends: _extends] = class_attr
    module = __CALLER__.module
    Module.put_attribute(module, :class_name, class_name)
    Module.put_attribute(module, :class_param, class_param)
    Module.put_attribute(module, :functions, [])
    block = Elixirdo.Base.Utils.rename_macro(:def, :__definstance_def, block)

    quote do
      unquote(class_name)()
      unquote(block)
      Elixirdo.Base.Instance.after_definstance()
    end
  end

  defmacro after_definstance() do
    module = __CALLER__.module
    functions = Utils.get_delete_attribute(module, :functions)
    class_name = Utils.get_delete_attribute(module, :class_name)
    class_param = Utils.get_delete_attribute(module, :class_param)
    typeclass_module = Utils.get_delete_attribute(module, :typeclass_module)
    typeclass_functions = Utils.get_delete_attribute(module, :typeclass_functions)

    IO.inspect(
      class_name: class_name,
      class_param: class_param,
      class_functions: typeclass_functions,
      functions: functions
    )

    inject_functions(typeclass_module, module, class_param, typeclass_functions, functions)
  end

  def inject_functions(class_module, module, class_param, class_functions, functions) do
    :lists.foldl(fn {name, arity}, acc ->
      impl_arities = Keyword.get_values(functions, name)

      case check_impls(arity, impl_arities) do
        {true, true} ->
          acc

        {true, false} ->
          [longdef(module, name, arity, class_param) | acc]

        {false, true} ->
          [shortdef(module, name, arity, class_param) | acc]

        {false, false} ->
          [shortdef(module, name, arity, class_param), default_def(class_module, module, name, arity)|acc]
      end
    end,[], class_functions)
  end

  def check_impls(arity, arities) do
    {:lists.member(arity, arities), :lists.member(arity + 1, arities)}
  end

  def shortdef(module, name, arity, class_param) do
    params = :lists.map(Utils.var_fn(module, "var"), :lists.seq(1, arity))

    quote do
      Kernel.def unquote(name)(unquote_splicing(params)) do
        unquote(name)(unquote_splicing(params), unquote(class_param))
      end
    end
  end

  def longdef(module, name, arity, class_param) do
    params = :lists.map(Utils.var_fn(module, "var"), :lists.seq(1, arity))

    quote do
      Kernel.def unquote(name)(unquote_splicing(params), unquote(class_param)) do
        unquote(name)(unquote_splicing(params))
      end
    end
  end

  def default_def(class_module, module, name, arity) do
    default_name = String.to_atom("__default__" <> Atom.to_string(name))
    params = :lists.map(Utils.var_fn(module, "var"), :lists.seq(1, arity + 1))

    quote do
      Kernel.def unquote(name)(unquote_splicing(params)) do
        unquote(class_module).unquote(default_name)(unquote_splicing(params))
      end
    end
  end

  defmacro deftype(type_spec) do
    type_spec |> IO.inspect(lable: type_spec)
    nil
  end

  defmacro __definstance_def({name, _, params}, do: block) do
    arity = length(params)
    module = __CALLER__.module

    Utils.update_attribute(module, :functions, fn functions ->
      :ordsets.add_element({name, arity}, functions)
    end)

    quote do
      Kernel.def unquote(name)(unquote_splicing(params)) do
        unquote(block)
      end
    end
  end
end
