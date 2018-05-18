defmodule Elixirdo.Either do
  use Elixirdo.Base
  use Elixirdo.Expand

  deftype either(e, a) :: {:left, a} | {:right, e}

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
