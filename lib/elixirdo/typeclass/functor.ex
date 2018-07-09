defmodule Elixirdo.Typeclass.Functor do
  use Elixirdo.Base
  use Elixirdo.Expand

  defmacro __using__(opts) do
    quote do
      alias Elixirdo.Typeclass.Functor
      unquote_splicing(__using_import__(opts))
    end
  end

  defclass functor(f) do
    def fmap((a -> b), f(a)) :: f(b)
  end
end
