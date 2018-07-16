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

    law identity(a: f(a)) do
      fmap(Function.id(), a) === Function.id(a)
    end

    law composition(a: f(a), f: (a -> b), g: (b -> c)) do
      fmap(Function.c(f, g), a) === Function.c(fmap(f, a), fmap(g, a))
    end
  end
end
