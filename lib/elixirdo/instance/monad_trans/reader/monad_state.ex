defmodule Elixirdo.Instance.MonadTrans.Reader.MonadState do
  use Elixirdo.Base
  use Elixirdo.Typeclass.Monad.State, import_monad_state: true

  alias Elixirdo.Instance.MonadTrans.Reader, as: ReaderT

  import_type ReaderT.reader_t()

  definstance monad_state(reader_t(r, m), m: monad_state) do
    def get() do
      MonadState.lift_get(m, reader_t)
    end

    def put(s) do
      MonadState.lift_put(s, m, reader_t)
    end

    def state(f) do
      MonadState.lift_state(f, m, reader_t)
    end
  end
end
