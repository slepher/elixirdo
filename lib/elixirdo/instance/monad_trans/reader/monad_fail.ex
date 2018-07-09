defmodule Elixirdo.Instance.MonadTrans.Reader.MonadFail do
  use Elixirdo.Base
  use Elixirdo.Typeclass.Monad.Fail, import_monad_fail: true

  import_type Elixirdo.Instance.MonadTrans.Reader.reader_t()

  definstance monad_fail(reader_t(r, m), m: monad) do
    def fail(e) do
      MonadFail.lift_fail(e, m, reader_t)
    end
  end
end
