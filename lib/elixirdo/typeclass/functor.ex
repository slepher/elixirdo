defmodule Elixirdo.Typeclass.Functor do
  use Elixirdo.Base

  defclass functor f do
    def fmap(a ~> b, f(a)) :: f(b)
  end
end
