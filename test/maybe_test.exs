defmodule MaybeTest do
  use ExUnit.Case
  alias Elixirdo.Typeclass.Functor
  alias Elixirdo.Typeclass.Applicative
  alias Elixirdo.Typeclass.Monad

  doctest Elixirdo.Instance.Maybe

  alias Elixirdo.Instance.Maybe

  @moduletag timeout: 1000

  test "fmap" do
    f = fn a -> a * 2 end
    just_2 = Maybe.Just.new(2)
    just_1 = Maybe.Just.new(1)
    nothing = Maybe.Nothing.new()
    assert just_2 == Functor.fmap(f, just_1)
    assert nothing == Functor.fmap(f, nothing)
  end

  test "ap" do
    mf = Maybe.Just.new(fn a -> a * 2 end)
    ma = Applicative.pure(1)
    mb = Maybe.Just.new(2)
    assert mb == Applicative.ap(mf, ma)
  end

  test "lift_a2" do
    f = fn a, b -> a + b end
    ma = Maybe.Just.new(3)
    mb = Maybe.Just.new(5)
    mc = Maybe.Just.new(8)
    assert mc == Applicative.lift_a2(f, ma, mb)
  end

  test "lift_a3" do
    f = fn a, b, c -> a + b + c end
    ma = Maybe.Just.new(3)
    mb = Maybe.Just.new(5)
    mc = Maybe.Just.new(8)
    md = Maybe.Just.new(16)
    assert md == Applicative.lift_a3(f, ma, mb, mc)
  end

  test "return" do
    ma = Maybe.Just.new(1)
    mb = Monad.return(1, :maybe)
    assert ma == mb
  end

  test "bind" do
    ma = Maybe.Just.new(1)
    k_mb = fn a -> Monad.return(a * 2) end
    mb = Maybe.Just.new(2)
    assert mb == Monad.bind(ma, k_mb)
  end
end
