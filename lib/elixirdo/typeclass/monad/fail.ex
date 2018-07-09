defmodule Elixirdo.Typeclass.Monad.Fail do
  use Elixirdo.Base
  use Elixirdo.Typeclass.Monad.Trans

  defmacro __using__(opts) do
    quote do
      use Elixirdo.Typeclass.Monad, unquote(opts)
      alias Elixirdo.Typeclass.Monad.Fail, as: MonadFail
      unquote_splicing(__using_import__(opts))
    end
  end

  defclass monad_fail(m, m: monad) do
    def fail(e) :: m
  end

  def lift_fail(e, monad, monad_trans) do
    MonadTrans.lift(fail(e, monad), monad_trans)
  end
end
