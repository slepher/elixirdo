defmodule Elixirdo.Typeclass.Traversable do
  use Elixirdo.Base
  use Elixirdo.Expand

  alias Elixirdo.Typeclass.Functor

  defmacro __using__(opts) do
    quote do
      use Elixirdo.Typeclass.Functor, unquote(opts)
      use Elixirdo.Typeclass.Foldable, unquote(opts)
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

    # naturality
    # t . traverse f = traverse (t . f) for every applicative transformation t
    # identity
    # traverse Identity = Identity
    # composition
    # traverse (Compose . fmap g . f) = Compose . fmap (traverse g) . traverse f

    law naturality(t: (f(b) -> g(c)), f: (a -> f(b)), ta: t(a)) :: g(t(c)), f: applicative, g: applicative do
      t.(traverse(f, ta)) === traverse(fn x -> t.(f.(x)) end, ta)
    end

    law identity(ta: t(a)) do
      traverse(fn a -> Identity.new(a) end, ta) === Identity.new(ta)
    end

    law composition(b_fc: (b -> f(c)), a_gb: (a -> g(b)), t: t(a)) :: t(Compose.compose(f, g, c)), f: applicative, g: applicative do
      traverse(fn a -> Compose.new(Functor.fmap(f, g.(a), f)) end, t) === Compose.new(Functor.fmap(fn tb -> Traversable.traverse(b_fc, tb, f) end, Traversable.traverse(a_gb, t, g), f))
    end
  end
end
