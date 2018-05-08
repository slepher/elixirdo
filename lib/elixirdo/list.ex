defmodule Elixirdo.List do
  use Elixirdo.Base

  alias Elixirdo.Typeclass.Applicative

  deftype list(a) :: [a]

  definstance functor list do
    def fmap(f, xs) do
      :lists.map(f, xs)
    end
  end

  definstance traversable list do
    def traverse(a_fb, [h|t]) do
      Applicative.lift_a2(fn hx,tx -> [hx|tx] end, a_fb.(h), traverse(a_fb, t))
    end
  end
end
