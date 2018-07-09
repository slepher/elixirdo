defmodule Elixirdo.Instance.MonadTrans.Writer.MonadReader do
  use Elixirdo.Base
  use Elixirdo.Typeclass.Monad.Reader, import_monad_reader: true

  alias Elixirdo.Instance.MonadTrans.Writer, as: WriterT

  import_type WriterT.writer_t()

  definstance monad_reader(writer_t(w, m), m: monad_reader) do
    def ask() do
      MonadReader.lift_ask(m, writer_t)
    end

    def reader(r) do
      MonadReader.lift_reader(r, m, writer_t)
    end

    def local(f, writer_t_a) do
      WriterT.map(&MonadReader.local(f, &1, m), writer_t_a)
    end
  end
end
