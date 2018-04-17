defmodule Elixirdo.Either do
  def either(fac, fbc) do
    fn eab ->
      case eab do
        {:left, a} ->
          fac.(a)

        {:right, b} ->
          fbc.(b)
      end
    end
  end
end
