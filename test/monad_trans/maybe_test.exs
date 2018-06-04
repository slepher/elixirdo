defmodule MonadTrans.MaybeTest do
  use ExUnit.Case
  alias Elixirdo.Instance.MonadTrans.Maybe
  alias Elixirdo.Typeclass.Functor
  alias Elixirdo.Typeclass.Applicative
  doctest Elixirdo.Instance.MonadTrans.Maybe

  @tag timeout: 1000
  test "fmap" do
    f = fn a -> a * 2 end
    assert %Maybe{data: {:just, {:just, 2}}} == Functor.fmap(f, %Maybe{data: {:just, {:just, 1}}})
  end

  @tag timeout: 1000
  test "ap" do
    mtf = %Maybe{data: {:right, {:just, fn a -> a * 2 end}}}
    mta = %Maybe{data: {:right, {:just, 1}}}
    mtb = %Maybe{data: {:right, {:just, 2}}}
    assert mtb == Applicative.ap(mtf, mta)
  end
end
