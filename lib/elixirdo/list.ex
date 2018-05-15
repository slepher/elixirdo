defmodule Elixirdo.List do
  use Elixirdo.Base
  use Elixirdo.Expand

  alias Elixirdo.Typeclass.Functor
  alias Elixirdo.Typeclass.Applicative

  import Functor, only: [functor: 0]
  import Applicative, only: [applicative: 0]
  import Elixirdo.Typeclass.Traversable, only: [traversable: 0]

  deftype list: 1

  definstance functor list do
    def fmap(f, xs) do
      :lists.map(f, xs)
    end
  end

  definstance applicative list do
    def pure(a) do
      [a]
    end

    def ap(list_f, list_a) do
      for f <- list_f do
        for a <- list_a do
          f.(a)
        end
      end
    end
  end

  definstance traversable list do
    def traverse(a_fb, [h|t]) do
      Applicative.lift_a2(fn hx,tx -> [hx|tx] end, a_fb.(h), traverse(a_fb, t))
    end
  end
end
