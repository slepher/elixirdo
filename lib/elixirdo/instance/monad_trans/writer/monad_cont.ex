defmodule Elixirdo.Instance.MonadTrans.Writer.MonadCont do
  use Elixirdo.Base
  use Elixirdo.Typeclass.Monad.Cont, import_monad_cont: true

  alias Elixirdo.Instance.MonadTrans.Writer, as: WriterT
  alias Elixirdo.Typeclass.Monoid

  import_type WriterT.writer_t()

  definstance monad_cont(writer_t(w, m), m: monad_cont) do
    def callCC(f) do
      WriterT.new(
        MonadCont.callCC(
          fn cc ->
            WriterT.run(f.(fn a -> WriterT.new(cc.({a, Monoid.mempty()})) end))
          end,
          m
        )
      )
    end
  end
end
