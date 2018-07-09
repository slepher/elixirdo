defmodule Elixirdo.Instance.MonadTrans.Except.MonadReader do
  use Elixirdo.Base
  use Elixirdo.Typeclass.Monad.Reader, import_monad_reader: true

  alias Elixirdo.Instance.MonadTrans.Except, as: ExceptT

  import_typeclass MonadReader.monad_reader()
  import_type ExceptT.except_t()

  definstance monad_reader(except_t(e, m), m: monad_reader) do
    def ask() do
      MonadReader.lift_ask(m, except_t)
    end

    def reader(r) do
      MonadReader.lift_reader(r, m, except_t)
    end

    def local(f, maybe_t_a) do
      ExceptT.map(&MonadReader.local(f, &1, m), maybe_t_a)
    end
  end
end
