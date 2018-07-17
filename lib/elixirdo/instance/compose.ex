defmodule Elixirdo.Instance.Compose do
  use Elixirdo.Base

  defstruct [:value]
  alias Elixirdo.Instance.Compose

  deftype compose(f, g, a) :: %Compose{value: f(g(a))}

  use Elixirdo.Typeclass.Applicative, import_applicative: true
  use Elixirdo.Typeclass.Traversable, import_functor: true, import_foldable: true, import_traversable: true

  def new(fga) do
    %Compose{value: fga}
  end

  def run(%Compose{value: fga}) do
    fga
  end

  definstance functor(compose(f, g), f: functor, g: functor) do
    def fmap(ab, compose_fga) do
      fga = run(compose_fga)
      new(Functor.fmap(fn ga -> Functor.fmap(ab, ga, g) end, fga, f))
    end
  end

  definstance applicative(compose(f, g), f: applicative, g: applicative) do
    def pure(a) do
      new(Applicative.pure(Applicative.pure(a, g), f))
    end

    def ap(compose_fg_ab, compose_fg_a) do
      fg_ab = run(compose_fg_ab)
      fg_a = run(compose_fg_a)
      new(Functor.fmap(fn g_a -> fn g_ab -> Applicative.ap(g_ab, g_a, g) end end, fg_ab, f) |> Applicative.ap(fg_a, f))
    end
  end

  definstance foldable(compose(f, g), f: foldable, g: foldable) do
    def foldMap(a_t, compose_fg_a) do
      fg_a = run(compose_fg_a)
      Foldable.foldMap(fn g_a -> Foldable.foldMap(a_t, g_a, g) end, fg_a, f)
    end
  end

  definstance traversable(compose(f, g), f: traversable, g: traversable) do
    def traverse(a_fb, compose_fg_a) do
      fg_a = run(compose_fg_a)
      Functor.fmap(&Compose.new/1, Traversable.traverse(fn g_a -> Traversable.traverse(a_fb, g_a, g) end, fg_a, f), f)
    end
  end
end
