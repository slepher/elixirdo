defmodule Elixirdo.Typeclass.Traversable do
  use Elixirdo.Base

  defclass traversable t, t: foldable, t: functor do
    def traverse(af_b: a ~> f(b), ta: t(a)) :: f(t(b)), f: applicative do
      t.sequence_a(t.fmap(af_b, ta))
    end

    def sequence_a(tfa: t(f(a))) :: f(t(a)), f: applicative do
      t.traverse(fn fa -> fa end, tfa)
    end
  end
end
