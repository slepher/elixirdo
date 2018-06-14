defmodule MonadTrans.ExceptTest do
  use ExUnit.Case
  alias Elixirdo.Instance.MonadTrans.Except
  alias Elixirdo.Typeclass.Functor
  alias Elixirdo.Typeclass.Applicative
  doctest Elixirdo.Instance.MonadTrans.Except

  use Elixirdo.Notation.Do
  use Elixirdo.Expand
  alias Elixirdo.Typeclass.Monad

  @tag timeout: 1000
  test "fmap" do
    f = fn a -> a * 2 end

    assert %Except{data: {:just, {:right, 2}}} == Functor.fmap(f, %Except{data: {:just, {:right, 1}}})
  end

  @tag timeout: 1000
  test "ap" do
    mtf = %Except{data: {:just, {:right, fn a -> a * 2 end}}}
    mta = %Except{data: {:just, {:right, 1}}}
    mtb = %Except{data: {:just, {:right, 2}}}
    assert mtb == Applicative.ap(mtf, mta)
  end

  @tag timeout: 1000
  test "bind" do
    mta = %Except{data: {:just, {:right, 1}}}
    mtb = %Except{data: {:just, {:right, 2}}}

    mtc =
      monad :monad do
        a <- mta
        Monad.return(a * 2)
      end

    assert mtb == mtc
  end
end
