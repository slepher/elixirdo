defmodule MonadTrans.ExceptTest do
  use ExUnit.Case
  alias Elixirdo.Typeclass.Functor
  alias Elixirdo.Typeclass.Applicative
  alias Elixirdo.Instance.MonadTrans.Except
  alias Elixirdo.Instance.Maybe
  alias Elixirdo.Instance.Either

  doctest Elixirdo.Instance.MonadTrans.Except

  use Elixirdo.Notation.Do
  use Elixirdo.Expand
  alias Elixirdo.Typeclass.Monad

  def except_just(a) do
    Except.new(Maybe.Just.new(Either.Right.new(a)))
  end

  @tag timeout: 1000
  test "fmap" do
    f = fn a -> a * 2 end
    except_just_1 = except_just(1)
    except_just_2 = except_just(2)
    assert except_just_2 == Functor.fmap(f, except_just_1)
  end

  @tag timeout: 1000
  test "ap" do
    mtf = except_just(fn a -> a * 2 end)
    mta = except_just(1)
    mtb = except_just(2)
    assert mtb == Applicative.ap(mtf, mta)
  end

  @tag timeout: 1000
  test "bind" do
    mta = except_just(1)
    mtb = except_just(2)
    mtc =
      monad :monad do
        a <- mta
        Monad.return(a * 2)
      end

    assert mtb == mtc
  end
end
