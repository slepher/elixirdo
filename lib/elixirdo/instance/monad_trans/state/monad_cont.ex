defmodule Elixirdo.Instance.MonadTrans.State.MonadCont do
  use Elixirdo.Base
  use Elixirdo.Typeclass.Monad.Cont, import_monad_cont: true

  alias Elixirdo.Instance.MonadTrans.State, as: StateT

  import_type StateT.state_t()

  definstance monad_cont(state_t(s, m), m: monad_cont) do
    def callCC(f) do
      StateT.new(
        fn s ->
        MonadCont.callCC(
          fn cc ->
            StateT.run(f.(fn a -> StateT.new(fn _ -> cc.({a, s}) end) end), s)
          end,
          m
        )
        end
      )
    end
  end
end
