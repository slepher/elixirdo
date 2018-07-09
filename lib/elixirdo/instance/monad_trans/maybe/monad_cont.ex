defmodule Elixirdo.Instance.MonadTrans.Maybe.MonadCont do
  use Elixirdo.Base
  use Elixirdo.Typeclass.Monad.Cont, import_monad_cont: true
  use Elixirdo.Instance.MonadTrans.Maybe

  import_type MaybeT.maybe_t()

  definstance monad_cont(maybe_t(m), m: monad_cont) do
    def callCC(f) do
      MaybeT.new(
        MonadCont.callCC(
          fn cc ->
            MaybeT.run(f.(fn a -> MaybeT.new(cc.(Just.new(a))) end))
          end,
          m
        )
      )
    end
  end
end
