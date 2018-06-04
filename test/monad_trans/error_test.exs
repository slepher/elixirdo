defmodule MonadTrans.ErrorTest do
  use ExUnit.Case
  alias Elixirdo.Instance.MonadTrans.Error
  alias Elixirdo.Typeclass.Functor
  alias Elixirdo.Typeclass.Applicative
  doctest Elixirdo.Instance.MonadTrans.Error

  use Elixirdo.Notation.Do
  alias Elixirdo.Typeclass.Monad

  @tag timeout: 1000
  test "fmap" do
    f = fn a -> a * 2 end
    assert %Error{data: {:just, {:right, 2}}} == Functor.fmap(f, %Error{data: {:just, {:right, 1}}})
  end

  @tag timeout: 1000
  test "ap" do
    mtf = %Error{data: {:just, {:right, fn a -> a * 2 end}}}
    mta = %Error{data: {:just, {:right, 1}}}
    mtb = %Error{data: {:just, {:right, 2}}}
    assert mtb == Applicative.ap(mtf, mta)
  end

  @tag timeout: 1000
  test "bind" do
    mta = %Error{data: {:just, {:right, 1}}}
    mtb = %Error{data: {:just, {:right, 2}}}

    mtc =
      monad :monad do
        a <- mta
        Monad.return(a * 2)
      end

    assert mtb == mtc
  end
end
