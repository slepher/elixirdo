defmodule Elixirdo.Typeclass.Profunctor do
  use Elixirdo.Base

  defclass profunctor(p) do
    def dimap((a -> b), (c -> d)) :: (p(b, c) -> p(a, d))
  end
end
