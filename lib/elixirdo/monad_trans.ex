defmodule Elixirdo.MonadTrans do

  alias Elixirdo.Undetermined
  alias Elixirdo.TypeclassTrans

  def lift(uma, umonad, umonad_trans) do
    Undetermined.new(fn monad_trans ->
        Undetermined.map0(fn monad, ma -> do_lift(ma, monad, monad_trans) end, uma, umonad)
    end, umonad_trans)
  end

  defp do_lift(ua, monad, monad_trans) do
    TypeclassTrans.apply(:lift, [ua, {monad_trans, monad}], monad_trans, :monad_trans)
  end

end
