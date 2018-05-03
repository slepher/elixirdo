defmodule Elixirdo.Typeclass.Traversable do

  import Elixirdo.Base.Class, only: [defclass: 2]

  defclass traversable t, t: foldable, t: functor do

    def traverse(af_b: a ~> f(b), ta: t(a)) :: f(t(b)), f: applicative, rest: c, do: t.sequence_a(t.fmap(af_b, ta))

    def sequence_a(tfa: t(f(a))) :: f(t(a)), f: applicative do
      t.traverse(fn fa -> fa end, tfa)
    end
  end
end
