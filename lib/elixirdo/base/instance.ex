defmodule Elixirdo.Base.Instance do
  defmacro __using__(_options) do
    quote do
      import Elixirdo.Base.Instance, only: :macros
    end
  end

  defmacro definstance(name, opts, do_block) do
    merged = Keyword.merge(opts, do_block)
    merged = Keyword.put_new(merged, :for, __CALLER__.module)
    __instance__(name, :lists.keysort(1, merged))
  end

  def __instance__(class, do: block, for: type) do
    quote do
      class = unquote(class)
      type = unquote(type)

      Module.register_attribute(__MODULE__, :idefs, accumulate: true)

      unquote(block)

      Module.register_attribute(__MODULE__, :p_class_instance, accumulate: true, persist: true)
      @p_class_instance [class: class, instance: type]
    end
  end
end
