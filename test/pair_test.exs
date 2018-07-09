defmodule PairTest do
  use ExUnit.Case
  use Elixirdo.Typeclass.Monad, import_typeclasses: true
  alias Elixirdo.Instance.Pair

  doctest Pair
  @moduletag timeout: 1000

  test "fmap" do
    pair_a = {10, 10}
    pair_b = {10, 20}
    assert pair_b == Functor.fmap(fn a -> a * 2 end, pair_a)
  end

  test "applicative" do
    pair_a = Applicative.pure(10)
    pair_f = {[:world], fn a -> a * 2 end}
    pair_b = {[:world], 20}
    assert pair_b == Applicative.ap(pair_f, pair_a)
  end
end
