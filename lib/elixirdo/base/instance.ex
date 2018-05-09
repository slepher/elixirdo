defmodule Elixirdo.Base.Instance do
  defmacro __using__(_) do
    quote do
      import Elixirdo.Base.Instance, only: [definstance: 2, __definstance_def: 2]
      alias Elixirdo.Typeclass.Register
    end
  end

  defmacro definstance(name, do: block) do
    class_attr = Elixirdo.Base.Utils.parse_class(name)
    [class: class_name, class_param: class_param, extends: _extends] = class_attr
    _extends |> IO.inspect(label: "extends")
    module = __CALLER__.module
    Module.put_attribute(module, :class_name, class_name)
    Module.put_attribute(module, :class_param, class_param)
    block = Elixirdo.Base.Utils.rename_macro(:def, :__definstance_def, block)
    [class: class_name, class_param: class_param, extends: _extends] = class_attr

    quote do

      unquote(class_name)()

      unquote(block)

    end
  end

  defmacro inspect_functions() do
    module = __CALLER__.module
    functions = Module.get_attribute(module, :functions)
    functions |> IO.inspect(label: "instance_functions")
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
    functions = Module.get_attribute(module, :functions, [])
    functions = functions || []
    functions = :ordsets.add_element({name, arity}, functions)
    Module.put_attribute(module, :functions, functions)
    IO.inspect [name: name, params: params, arity: arity, meta_class: meta_class, class_name: class_name]
    quote do
      Kernel.def unquote(name)(unquote_splicing(params)) do
        unquote(block)
      end
    end
  end

end
