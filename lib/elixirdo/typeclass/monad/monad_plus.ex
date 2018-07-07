defmodule Elixirdo.Typeclass.Monad.MonadPlus do

  use Elixirdo.Base
  use Elixirdo.Typeclass.Monad

  defclass monad_plus(m, m: monad) do
    def mzero() :: m(a)

    def mplus(m(a), m(a)) :: m(a)
  end

  def guard(cond) do
    guard(cond, :monad_plus)
  end

  def guard(true, m) do
    Monad.return({}, m)
  end

  def guard(false, m) do
    mzero(m)
  end
end
