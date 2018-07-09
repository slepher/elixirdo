defmodule Elixirdo.Typeclass.Traversable do
  use Elixirdo.Base
  use Elixirdo.Expand

  alias Elixirdo.Typeclass.Functor

  defmacro __using__(opts) do
    quote do
      alias Elixirdo.Typeclass.Traversable
      unquote_splicing(__using_import__(opts))
    end
  end

  defclass traversable(t, t: foldable, t: functor) do
    def traverse(af_b: (a -> f(b)), ta: t(a)) :: f(t(b)), f: applicative do
      sequence_a(Functor.fmap(af_b, ta, t), t)
    end

    def sequence_a(tfa: t(f(a))) :: f(t(a)), f: applicative do
      traverse(fn fa -> fa end, tfa, t)
    end
  end
end
