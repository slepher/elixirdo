
  defmodule Elixirdo.Instance.MonadTrans.Except.MonadWriter do
    use Elixirdo.Base
    use Elixirdo.Typeclass.Monad
    use Elixirdo.Typeclass.Monad.Writer, import_monad_writer: true
    use Elixirdo.Instance.MonadTrans.Except

    import_type ExceptT.except_t()

    definstance monad_writer(except_t(e, m), m: monad_writer) do
      def writer({a, w}) do
        MonadWriter.lift_writer({a, w}, m, except_t)
      end

      def tell(w) do
        MonadWriter.lift_tell(w, m, except_t)
      end

      def listen(except_t_a) do
        ExceptT.map(
          fn monad_writer_a ->
            monad m do
              {either_a, w} <- MonadWriter.listen(monad_writer_a, m)
              Monad.return(Functor.fmap(fn a -> {a, w} end, either_a, :either), m)
            end
          end,
          except_t_a
        )
      end

      def pass(except_t_a) do
        ExceptT.map(
          fn monad_writer_a ->
            MonadWriter.pass(
              monad m do
                either_a <- monad_writer_a
                Monad.return(transform(either_a), m)
              end,
              m
            )
          end,
          except_t_a
        )
      end
    end

    def transform(either_a) do
      case either_a do
        %Right{} ->
          {a, f} = Right.run(either_a)
          {Right.new(a), f}

        %Left{} ->
          reason = Left.run(either_a)
          {Left.new(reason), fn a -> a end}
      end
    end
  end
