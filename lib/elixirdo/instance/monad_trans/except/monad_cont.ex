defmodule Elixirdo.Instance.MonadTrans.Except.MonadCont do
  use Elixirdo.Base
  use Elixirdo.Instance.MonadTrans.Except
  use Elixirdo.Typeclass.Monad.Cont, import_typeclass: true

  import_type ExceptT.except_t()

  definstance monad_cont(except_t(e, m), m: monad_cont) do
    def callCC(f) do
      ExceptT.new(
        MonadCont.callCC(
          fn cc ->
            ExceptT.run(f.(fn a -> ExceptT.new(cc.(Right.new(a))) end))
          end,
          m
        )
      )
    end
  end
end
