defmodule MaybeTTest do
  use ExUnit.Case
  alias Elixirdo.Instance.MonadTrans.MaybeT
  alias Elixirdo.Typeclass.Functor
  alias Elixirdo.Typeclass.Applicative
  doctest Elixirdo.Instance.MonadTrans.MaybeT

  @tag timeout: 1000
  test "fmap" do
    f = fn a -> a * 2 end
    assert %MaybeT{data: {:just, {:just, 2}}} == Functor.fmap(f, %MaybeT{data: {:just, {:just, 1}}})
  end

  @tag timeout: 1000
  test "ap" do
    mtf = %MaybeT{data: {:right, {:just, fn a -> a * 2 end}}}
    mta = %MaybeT{data: {:right, {:just, 1}}}
    mtb = %MaybeT{data: {:right, {:just, 2}}}
    assert mtb == Applicative.ap(mtf, mta)
  end
end
