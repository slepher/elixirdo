defmodule MaybeTest do
  use ExUnit.Case
  alias Elixirdo.Typeclass.Functor
  alias Elixirdo.Typeclass.Applicative

  doctest Elixirdo.Maybe

  @tag timeout: 1000
  test "fmap" do
    f = fn a -> a * 2 end
    assert {:just, 2} == Functor.fmap(f, {:just, 1})
    assert :nothing == Functor.fmap(f, :nothing)
  end

  @tag timeout: 1000
  test "ap" do
    mtf = {:just, fn a -> a * 2 end}
    mta = Applicative.pure(1)
    mtb = {:just, 2}
    assert mtb == Applicative.ap(mtf, mta)
  end
end
