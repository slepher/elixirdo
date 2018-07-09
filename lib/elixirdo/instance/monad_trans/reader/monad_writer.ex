defmodule Elixirdo.Instance.MonadTrans.Reader.MonadWriter do
  use Elixirdo.Base
  use Elixirdo.Expand
  use Elixirdo.Typeclass.Monad.Writer, import_monad_writer: true

  alias Elixirdo.Instance.MonadTrans.Reader, as: ReaderT

  import_type ReaderT.reader_t()

  definstance monad_writer(reader_t(e, m), m: monad_writer) do
    def writer({a, w}) do
      MonadWriter.lift_writer({a, w}, m, reader_t)
    end

    def tell(w) do
      MonadWriter.lift_tell(w, m, reader_t)
    end

    def listen(reader_t_a) do
      ReaderT.map(
        fn monad_writer_a ->
          MonadWriter.listen(monad_writer_a, m)
        end,
        reader_t_a
      )
    end

    def pass(reader_t_a) do
      ReaderT.map(
        fn monad_writer_a ->
          MonadWriter.pass(monad_writer_a, m)
        end,
        reader_t_a
      )
    end
  end
end
