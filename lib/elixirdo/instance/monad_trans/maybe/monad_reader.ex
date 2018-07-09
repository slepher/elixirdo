defmodule Elixirdo.Instance.MonadTrans.Maybe.MonadReader do
  use Elixirdo.Base
  use Elixirdo.Typeclass.Monad.Reader, import_typeclass: true

  alias Elixirdo.Instance.MonadTrans.Maybe, as: MaybeT

  import_type MaybeT.maybe_t()

  definstance monad_reader(maybe_t(m), m: monad_reader) do
    def ask() do
      MonadReader.lift_ask(m, maybe_t)
    end

    def reader(r) do
      MonadReader.lift_reader(r, m, maybe_t)
    end

    def local(f, maybe_t_a) do
      MaybeT.map(&MonadReader.local(f, &1, m), maybe_t_a)
    end
  end
end
