defmodule Elixirdo.Instance.MonadTrans.Cont.MonadState do
  use Elixirdo.Base
  use Elixirdo.Typeclass.Monad.State, import_typeclass: true
  alias Elixirdo.Instance.MonadTrans.Cont, as: ContT

  import_type ContT.cont_t()

  definstance monad_state(cont_t(r, m), m: monad_state) do
    def get() do
      MonadState.lift_get(m, cont_t)
    end

    def put(s) do
      MonadState.lift_put(s, m, cont_t)
    end

    def state(f) do
      MonadState.lift_state(f, m, cont_t)
    end
  end
end
