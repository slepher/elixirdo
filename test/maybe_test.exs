defmodule MaybeTest do
  use ExUnit.Case
  alias Elixirdo.Typeclass.Functor
  alias Elixirdo.Typeclass.Applicative
  alias Elixirdo.Typeclass.Monad

  doctest Elixirdo.Instance.Maybe

  @moduletag timeout: 1000

  test "fmap" do
    f = fn a -> a * 2 end
    assert {:just, 2} == Functor.fmap(f, {:just, 1})
    assert :nothing == Functor.fmap(f, :nothing)
  end

  @tag timeout: 1000
  test "ap" do
    mf = {:just, fn a -> a * 2 end}
    ma = Applicative.pure(1)
    mb = {:just, 2}
    assert mb == Applicative.ap(mf, ma)
  end

  @tag timeout: 1000
  test "lift_a2" do
    f = fn a, b -> a + b end
    ma = {:just, 3}
    mb = {:just, 5}
    mc = {:just, 8}
    assert mc == Applicative.lift_a2(f, ma, mb)
  end

  @tag timeout: 1000
  test "lift_a3" do
    f = fn a, b, c -> a + b + c end
    ma = {:just, 3}
    mb = {:just, 5}
    mc = {:just, 8}
    md = {:just, 16}
    assert md == Applicative.lift_a3(f, ma, mb, mc)
  end

  test "return" do
    ma = {:just, 1}
    mb = Monad.return(1, :maybe)
    assert ma == mb
  end

  test "bind" do
    ma = {:just, 1}
    k_mb = fn a -> Monad.return(a * 2) end
    mb = {:just, 2}
    assert mb == Monad.bind(ma, k_mb)
  end
end
