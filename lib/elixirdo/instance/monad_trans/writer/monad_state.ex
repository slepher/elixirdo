defmodule Elixirdo.Instance.MonadTrans.Writer.MonadState do
  use Elixirdo.Base
  use Elixirdo.Typeclass.Monad.State, import_typeclass: true
  alias Elixirdo.Instance.MonadTrans.Writer, as: WriterT

  import_type WriterT.writer_t()

  definstance monad_state(writer_t(w, m), m: monad_state) do
    def get() do
      MonadState.lift_get(m, writer_t)
    end

    def put(s) do
      MonadState.lift_put(s, m, writer_t)
    end

    def state(f) do
      MonadState.lift_state(f, m, writer_t)
    end
  end
end
