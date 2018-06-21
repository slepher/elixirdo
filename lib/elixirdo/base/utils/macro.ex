defmodule Elixirdo.Base.Utils.Macro do

  def rename_macro(from, to, block) do
    Macro.prewalk(
      block,
      fn
        {from_def, ctx, fun} when from_def == from ->
          {to, ctx, fun}

        ast ->
          ast
      end
    )
  end

  defmacro with_opts_and_do(name, rename) do
    quote do
      defmacro unquote(name)(params) do
        unquote(rename)(params, [], nil, __CALLER__.module)
      end

      defmacro unquote(name)(params, opts) do
        {opts, block} = Elixirdo.Base.Utils.Macro.split_block(opts, nil)
        unquote(rename)(params, opts, block, __CALLER__.module)
      end

      defmacro unquote(name)(params, opts, do_block) do
        {opts, block} = Elixirdo.Base.Utils.Macro.split_block(opts, do_block)
        unquote(rename)(params, opts, block, __CALLER__.module)
      end
    end
  end

  def split_block([do: block], nil) do
    {[], block}
  end

  def split_block(opts, nil) do
    {block, opts} = Keyword.pop(opts, :do, nil)
    {opts, block}
  end

  def split_block(opts, do: block) do
    {opts, block}
  end

  defmacro set_attribute(key, value) do
    module = __CALLER__.module
    Module.put_attribute(module, key, value)
    nil
  end

  def update_attribute(module, key, fun) do
    attribute = Module.get_attribute(module, key)
    attribute = fun.(attribute)
    Module.put_attribute(module, key, attribute)
  end

  def get_delete_attribute(module, key) do
    attribute = Module.get_attribute(module, key)
    Module.delete_attribute(module, key)
    attribute
  end

  def export_attribute(module, name, value) do
    export_attribute(module, name, value, value)
  end

  def export_attribute(module, name, value, fun_value) do
    Module.put_attribute(module, name, value)

    quote do
      def unquote(name)() do
        unquote(fun_value)
      end
    end
  end

  def exported_attribute(module, target_module, attribute_name) do
    if(module == target_module) do
      Module.get_attribute(module, attribute_name)
    else
      :erlang.apply(target_module, attribute_name, [])
    end
  end

  def import_attribute(module, target_module, attribute_name) do
    if(module == target_module) do
      Module.get_attribute(module, attribute_name)
    else
      attribute_value = :erlang.apply(target_module, attribute_name, [])
      Module.put_attribute(module, attribute_name, attribute_value)
      attribute_value
    end
  end

  def import_attribute_module(caller, {{:., _, [from_module, attribute]}, _, _}) do
    module = caller.module
    from_module = Macro.expand(from_module, caller)
    import_attribute(module, from_module, attribute)
    nil
  end
end
