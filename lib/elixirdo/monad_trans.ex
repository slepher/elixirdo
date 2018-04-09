defmodule Elixirdo.MonadTrans do

  alias Elixirdo.Undetermined

  def lift(uA, uMonadTrans) do
    Undetermined.new(fn
      monadTrans when is_atom(monadTrans) ->
        monadTrans.lift(uA, monadTrans)
      {monadTrans, uMonad} ->
        Undetermined.map0(fn monad, mA -> monadTrans.lift(mA, {monadTrans, monad}) end, uA, uMonad)
    end, uMonadTrans)
  end

end
