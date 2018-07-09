defmodule Elixirdo.Instance.MonadTrans.State.MonadWriter do
  use Elixirdo.Base
  use Elixirdo.Expand
  use Elixirdo.Typeclass.Monad
  use Elixirdo.Typeclass.Monad.Writer, import_monad_writer: true

  alias Elixirdo.Instance.MonadTrans.State, as: StateT

  import_type StateT.state_t()

  definstance monad_writer(state_t(s, m), m: monad_writer) do
    def writer({a, w}) do
      MonadWriter.lift_writer({a, w}, m, state_t)
    end

    def tell(w) do
      MonadWriter.lift_tell(w, m, state_t)
    end

    def listen(state_t_a) do
      StateT.map(
        fn monad_writer_a ->
          monad m do
            {{a, s}, w} <- MonadWriter.listen(monad_writer_a, m)
            Monad.return({{a, w}, s}, m)
          end
        end,
        state_t_a
      )
    end

    def pass(state_t_a) do
      StateT.map(
        fn monad_writer_a ->
          MonadWriter.pass(
            monad m do
              {{a, f}, s} <- monad_writer_a
              Monad.return({{a, s}, f}, m)
            end,
            m
          )
        end,
        state_t_a
      )
    end
  end
end
