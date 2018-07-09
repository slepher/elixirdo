defmodule Elixirdo.Instance.MonadTrans.Except.MonadState do
  use Elixirdo.Base
  use Elixirdo.Typeclass.Monad.State, import_monad_state: true

  alias Elixirdo.Instance.MonadTrans.Except, as: ExceptT

  import_type ExceptT.except_t()

  definstance monad_state(except_t(e, m), m: monad_state) do
    def get() do
      MonadState.lift_get(m, except_t)
    end

    def put(s) do
      MonadState.lift_put(s, m, except_t)
    end

    def state(f) do
      MonadState.lift_state(f, m, except_t)
    end
  end
end
