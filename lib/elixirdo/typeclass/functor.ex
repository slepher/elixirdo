defmodule Elixirdo.Typeclass.Functor do
  use Elixirdo.Base
  use Elixirdo.Expand

  defclass functor(f) do
    def fmap((a -> b), f(a)) :: f(b)
  end
end
