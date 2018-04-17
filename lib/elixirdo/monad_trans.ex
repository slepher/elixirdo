defmodule Elixirdo.MonadTrans do

  alias Elixirdo.Undetermined
  alias Elixirdo.TypeclassTrans

  def lift(uma, umonad_trans) do
    Undetermined.new(fn
      monad_trans when is_atom(monad_trans) ->
        monad_trans.lift(uma)
      {monad_trans, umonad} ->
        Undetermined.map0(fn monad, ma -> do_lift(ma, {monad_trans, monad}) end, uma, umonad)
    end, umonad_trans)
  end

  def do_lift(ma, monad_trans) do
    TypeclassTrans.apply(:lift, [ma], monad_trans, :monad_trans)
  end
end
