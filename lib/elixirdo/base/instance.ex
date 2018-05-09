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
    _extends |> IO.inspect(label: "extends")
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
    typeclass_functions = Utils.get_delete_attribute(module, :typeclass_functions)
    IO.inspect [class_name: class_name, class_param: class_param, class_functions: typeclass_functions, functions: functions]
    nil
  end

  defmacro deftype(type_spec) do
    type_spec |> IO.inspect(lable: type_spec)
    nil
  end

  defmacro __definstance_def({name, _, params}, do: block) do
    arity = length(params)
    module = __CALLER__.module

    class_name = Module.get_attribute(module, :class_name)
    class_param = Module.get_attribute(module, :class_param)
    typeclass_module = Module.get_attribute(module, :typeclass_module)

    Utils.update_attribute(module, :functions, fn functions -> :ordsets.add_element({name, arity}, functions) end)

    quote do
      Kernel.def unquote(name)(unquote_splicing(params)) do
        unquote(block)
      end
    end
  end

end
