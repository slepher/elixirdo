defmodule Elixirdo.Typeclass.Monad.MonadFail do

  use Elixirdo.Base

  defclass monad_fail(m, m: monad) do
    def fail(e) :: m
  end
end
