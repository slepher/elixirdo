defmodule MaybeTTest do
  use ExUnit.Case
  doctest Elixirdo.MaybeT

  test "fmap" do
    f = fn a -> a * 2 end
    assert %Elixirdo.MaybeT{data: {:just, {:just, 2}}} == Elixirdo.Functor.fmap(f, %Elixirdo.MaybeT{data: {:just, {:just, 1}}})
  end

  test "ap" do
    mtf = %Elixirdo.MaybeT{data: {:just, {:just, fn a -> a * 2 end}}}
    mta = %Elixirdo.MaybeT{data: {:just, {:just, 1}}}
    mtb = %Elixirdo.MaybeT{data: {:just, {:just, 2}}}
    assert mtb == Elixirdo.Applicative.ap(mtf, mta)
  end
end
