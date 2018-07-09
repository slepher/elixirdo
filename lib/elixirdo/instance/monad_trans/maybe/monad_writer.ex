
  defmodule Elixirdo.Instance.MonadTrans.Maybe.MonadWriter do
    use Elixirdo.Base
    use Elixirdo.Typeclass.Monad
    use Elixirdo.Typeclass.Monad.Writer, import_monad_writer: true
    use Elixirdo.Instance.MonadTrans.Maybe

    import_type MaybeT.maybe_t()

    definstance monad_writer(maybe_t(m), m: monad_writer) do
      def writer({a, w}) do
        MonadWriter.lift_writer({a, w}, m, maybe_t)
      end

      def tell(w) do
        MonadWriter.lift_tell(w, m, maybe_t)
      end

      def listen(maybe_t_a) do
        MaybeT.map(
          fn monad_writer_a ->
            monad m do
              {maybe_a, w} <- MonadWriter.listen(monad_writer_a, m)
              Monad.return(Functor.fmap(fn a -> {a, w} end, maybe_a, :maybe), m)
            end
          end,
          maybe_t_a
        )
      end

      def pass(maybe_t_a) do
        MaybeT.map(
          fn monad_writer_a ->
            MonadWriter.pass(
              monad m do
                maybe_a <- monad_writer_a
                Monad.return(transform(maybe_a), m)
              end,
              m
            )
          end,
          maybe_t_a
        )
      end
    end

    def transform(maybe_a) do
      case maybe_a do
        %Just{} ->
          {a, f} = Just.run(maybe_a)
          {Just.new(a), f}

        %Nothing{} ->
          {Nothing.new(), fn a -> a end}
      end
    end
  end
