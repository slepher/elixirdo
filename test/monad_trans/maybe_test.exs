defmodule MonadTrans.MaybeTest do
  use ExUnit.Case
  alias Elixirdo.Instance.MonadTrans.Maybe, as: MaybeT
  alias Elixirdo.Instance.Maybe.Just

  alias Elixirdo.Typeclass.Functor
  alias Elixirdo.Typeclass.Applicative
  doctest Elixirdo.Instance.MonadTrans.Maybe

  def just_just(a) do
    MaybeT.new(Just.new(Just.new(a)))
  end

  @tag timeout: 1000
  test "fmap" do
    f = fn a -> a * 2 end
    just_just_1 = just_just(1)
    just_just_2 = just_just(2)
    assert just_just_2 == Functor.fmap(f, just_just_1)
  end

  @tag timeout: 1000
  test "ap" do
    mtf = just_just(fn a -> a * 2 end)
    mta = just_just(1)
    mtb = just_just(2)
    assert mtb == Applicative.ap(mtf, mta)
  end
end
