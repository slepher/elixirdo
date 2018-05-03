defmodule Elixirdo.Base.Utils do
  def rename_macro(from, to, block) do
    funs =
      case block do
        nil -> []
        {:__block__, _ctx, funs} -> funs
        fun = {from_def, _ctx, _inner} when from_def == from -> [fun]
      end

    funs
    |> List.wrap()
    |> Enum.map(fn
      {from_def, ctx, fun} when from_def == from ->
        {to, ctx, fun}
      ast ->
        ast
    end)
  end

  defmacro set_attribute(key, value) do
    module = __CALLER__.module
    Module.put_attribute(module, key, value)
    nil
  end
end
