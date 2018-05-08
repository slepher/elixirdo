defmodule Elixirdo.Base.Instance do
  defmacro __using__(_) do
    quote do
      import Elixirdo.Base.Instance, only: [definstance: 2, __definstance_def: 2]
    end
  end

  defmacro definstance(name, do: block) do
    block |> IO.inspect(label: "block")
    class_attr = Elixirdo.Base.Utils.parse_class(name)
    [class: class_name, class_param: class_param, extends: _extends] = class_attr
    module = __CALLER__.module
    Module.put_attribute(module, class_name, class_param)
    block = Elixirdo.Base.Utils.rename_macro(:def, :__definstance_def, block)

    quote do
      unquote(block)
    end
  end

  defmacro deftype(type_spec) do
    type_spec |> IO.inspect(lable: type_spec)
    nil
  end


  defmacro __definstance_def({name, _, params}, do: block) do
    arity = length(params)
    module = __CALLER__.module
    functions = Module.get_attribute(module, :functions, [])
    functions = functions || []
    functions = :ordsets.add_element({name, arity}, functions)
    Module.put_attribute(module, :functions, functions)
    IO.inspect [name: name, params: params, arity: arity]
    quote do
      Kernel.def unquote(name)(unquote_splicing(params)) do
        unquote(block)
      end
    end
  end

end
