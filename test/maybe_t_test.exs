defmodule MaybeTTest do
  use ExUnit.Case
  alias Elixirdo.MaybeT
  alias Elixirdo.Typeclass.Functor
  alias Elixirdo.Typeclass.Applicative
  doctest Elixirdo.MaybeT

  @tag timeout: 1000
  test "fmap" do
    f = fn a -> a * 2 end
    assert %MaybeT{data: {:just, {:just, 2}}} == Functor.fmap(f, %MaybeT{data: {:just, {:just, 1}}})
  end

  @tag timeout: 1000
  test "ap" do
    mtf = %MaybeT{data: {:just, {:just, fn a -> a * 2 end}}}
    mta = %MaybeT{data: {:just, {:just, 1}}}
    mtb = %MaybeT{data: {:just, {:just, 2}}}
    assert mtb == Applicative.ap(mtf, mta)
  end
end
