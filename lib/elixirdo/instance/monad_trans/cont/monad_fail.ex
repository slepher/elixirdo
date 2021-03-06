defmodule Elixirdo.Instance.MonadTrans.Cont.MonadFail do
  use Elixirdo.Base
  use Elixirdo.Typeclass.Monad.Fail, import_monad_fail: true

  import_type Elixirdo.Instance.MonadTrans.Cont.cont_t()

  definstance monad_fail(cont_t(r, m), m: monad) do
    def fail(e) do
      MonadFail.lift_fail(e, m, cont_t)
    end
  end
end
