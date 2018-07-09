defmodule Elixirdo.Instance.MonadTrans.Reader.MonadCont do
  use Elixirdo.Base
  use Elixirdo.Typeclass.Monad.Cont, import_typeclass: true

  alias Elixirdo.Instance.MonadTrans.Reader, as: ReaderT

  import_type ReaderT.reader_t()

  definstance monad_cont(reader_t(r, m), m: monad_cont) do
    def callCC(f) do
      ReaderT.new(
        fn r ->
        MonadCont.callCC(
          fn cc ->
            ReaderT.run(f.(fn a -> ReaderT.new(fn _ -> cc.(a) end) end), r)
          end,
          m
        )
        end
      )
    end
  end
end
