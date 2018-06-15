defmodule Elixirdo.Instance.List do
  use Elixirdo.Base
  use Elixirdo.Expand

  use Elixirdo.Typeclass.Monad
  use Elixirdo.Typeclass.Monoid
  use Elixirdo.Typeclass.Foldable
  use Elixirdo.Typeclass.Traversable

  deftype anonymous(a) :: list(a), as: :list

  definstance functor(list) do
    def fmap(f, xs) do
      :lists.map(f, xs)
    end
  end

  definstance applicative(list) do
    def pure(a) do
      [a]
    end

    def ap(list_f, list_a) do
      :lists.flatten(for f <- list_f, do: for(a <- list_a, do: f.(a)))
    end
  end

  definstance monad(list) do
    def bind(as, afb) do
      :lists.flatten(:lists.map(fn a -> afb.(a) end, as))
    end
  end

  definstance monoid(list) do
    def empty() do
      []
    end

    def append(list_a, list_b) do
      list_a ++ list_b
    end
  end

  definstance foldable(list) do
    def foldMap(afm, [h | t]) do
      Monoid.append(afm.(h), foldMap(afm, t))
    end
  end

  definstance traversable(list) do
    def traverse(a_fb, [h | t]) do
      Applicative.lift_a2(fn hx, tx -> [hx | tx] end, a_fb.(h), traverse(a_fb, t))
    end

    def traverse(_a_fb, []) do
      Applicative.pure([])
    end
  end
end
