defmodule Elixirdo.MonadTrans do

  alias Elixirdo.Undetermined
  alias Elixirdo.TypeclassTrans

  def lift(ua, umonad_trans) do
    Undetermined.new(fn
      monad_trans when is_atom(monad_trans) ->
        do_lift(ua, monad_trans, :monad)
      {monad_trans, umonad} ->
        Undetermined.map0(fn monad, ma -> do_lift(ma, monad_trans, monad) end, ua, umonad)
    end, umonad_trans)
  end

  defp do_lift(ua, monad_trans, monad) do
    TypeclassTrans.apply(:lift, [ua, {monad_trans, monad}], monad_trans, :monad_trans)
  end

end
