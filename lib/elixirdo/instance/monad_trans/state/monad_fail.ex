defmodule Elixirdo.Instance.MonadTrans.State.MonadFail do
  use Elixirdo.Base
  use Elixirdo.Typeclass.Monad.Fail, import_monad_fail: true

  import_type Elixirdo.Instance.MonadTrans.State.state_t()

  definstance monad_fail(state_t(s, m), m: monad) do
    def fail(e) do
      MonadFail.lift_fail(e, m, state_t)
    end
  end
end
