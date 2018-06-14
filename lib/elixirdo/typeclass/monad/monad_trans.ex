defmodule Elixirdo.Typeclass.Monad.MonadTrans do
  use Elixirdo.Base

  alias Elixirdo.Base.Undetermined
  alias Elixirdo.Base.Generated

  defmacro __using__(_) do
    quote do
      alias Elixirdo.Typeclass.Monad.MonadTrans
      import_typeclass MonadTrans.monad_trans()
    end
  end

  defclass monad_trans(t) do
    def lift(m(a)) :: t(m, a), m: monad
  end

  def lift2(uma, %{t: umonad_trans, m: umonad}) do
    Undetermined.map_list(
      fn [], monad_trans ->
        Undetermined.map_list(
          fn [ma], monad ->
            module = Generated.module(monad_trans, :monad_trans)
            module.lift(ma, %{t: monad_trans, m: monad})
          end,
          [uma],
          umonad
        )
      end,
      [],
      umonad_trans
    )
  end
end
