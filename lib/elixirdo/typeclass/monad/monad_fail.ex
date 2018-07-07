defmodule Elixirdo.Typeclass.Monad.MonadFail do
  use Elixirdo.Base

  defmacro __using__(_) do
    quote do
      alias Elixirdo.Typeclass.Monad.MonadFail
      import_typeclass MonadFail.monad_fail()
    end
  end

  defclass monad_fail(m, m: monad) do
    def fail(e) :: m
  end
end
