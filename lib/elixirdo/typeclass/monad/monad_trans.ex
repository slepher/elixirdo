defmodule Elixirdo.Typeclass.Monad.MonadTrans do

  alias Elixirdo.Base.Undetermined
  alias Elixirdo.Base.Generated

  def lift(uma, umonad_trans) do
    Undetermined.new(fn
      monad_trans when is_atom(monad_trans) ->
        do_lift(uma, monad_trans)
      {monad_trans, umonad} ->
        Undetermined.map(fn monad, ma -> do_lift(ma, {monad_trans, monad}) end, uma, umonad)
    end, umonad_trans)
  end

  def do_lift(ma, monad_trans) do
    module = Generated.module(monad_trans, :monad_trans)
    module.lift(ma, monad_trans)
  end
end
