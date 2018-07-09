defmodule Elixirdo.Instance.MonadTrans.Maybe.MonadState do
  use Elixirdo.Base
  use Elixirdo.Typeclass.Monad.State, import_typeclass: true

  alias Elixirdo.Instance.MonadTrans.Maybe, as: MaybeT

  import_type MaybeT.maybe_t()

  definstance monad_state(maybe_t(m), m: monad_state) do
    def get() do
      MonadState.lift_get(m, maybe_t)
    end

    def put(s) do
      MonadState.lift_put(s, m, maybe_t)
    end

    def state(f) do
      MonadState.lift_state(f, m, maybe_t)
    end
  end
end
