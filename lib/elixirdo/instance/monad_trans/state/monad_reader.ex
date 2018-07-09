defmodule Elixirdo.Instance.MonadTrans.State.MonadReader do
  use Elixirdo.Base
  use Elixirdo.Typeclass.Monad
  use Elixirdo.Typeclass.Monad.Reader, import_typeclass: true

  alias Elixirdo.Instance.MonadTrans.State, as: StateT

  import_type StateT.state_t()

  definstance monad_reader(state_t(s, m), m: monad_reader) do
    def ask() do
      MonadReader.lift_ask(m, state_t)
    end

    def reader(r) do
      MonadReader.lift_reader(r, m, state_t)
    end

    def local(f, state_t_a) do
      StateT.map(&MonadReader.local(f, &1, m), state_t_a)
    end
  end
end
