defmodule Elixirdo.Instance.Pair do

  use Elixirdo.Base
  use Elixirdo.Typeclass.Monad, import_typeclasses: true

  alias Elixirdo.Typeclass.Monoid

  deftype pair(a, b) :: {a, b}

  definstance functor(pair(a, b)) do
   def fmap(f, {m, a}) do
     {m, f.(a)}
   end
  end

  definstance applicative(pair(m, a), m: monoid) do
    def pure(a) do
      {Monoid.mempty(), a}
    end

    def ap({m1, f}, {m2, a}) do
      {Monoid.mappend(m1, m2), f.(a)}
    end
  end

  definstance monad(pair(m, a), m: monoid) do
    def bind({m1, a}, afb) do
      {m2, b} = afb.(a)
      {Monoid.mappend(m1, m2), b}
    end
  end
end
