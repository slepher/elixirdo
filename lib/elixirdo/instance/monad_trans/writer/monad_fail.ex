defmodule Elixirdo.Instance.MonadTrans.Writer.MonadFail do
  use Elixirdo.Base
  use Elixirdo.Typeclass.Monad.Fail, import_typeclass: true

  import_type Elixirdo.Instance.MonadTrans.Writer.writer_t()

  definstance monad_fail(writer_t(w, m), m: monad) do
    def fail(e) do
      MonadFail.lift_fail(e, m, writer_t)
    end
  end
end
