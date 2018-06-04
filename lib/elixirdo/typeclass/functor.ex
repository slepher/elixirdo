defmodule Elixirdo.Typeclass.Functor do
  use Elixirdo.Base
  use Elixirdo.Expand

  defmacro __using__(_) do
    quote do
      alias Elixirdo.Typeclass.Functor
      import Elixirdo.Typeclass.Functor, only: [functor: 0]
    end
  end

  defclass functor(f) do
    def fmap((a -> b), f(a)) :: f(b)
  end
end
