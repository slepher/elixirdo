defmodule MonadTrans.State do
  use ExUnit.Case
  alias Elixirdo.Instance.MonadTrans.State
  alias Elixirdo.Typeclass.Monad.MonadState
  alias Elixirdo.Base.Undetermined

  doctest State

  @tag timeout: 1000
  test "get" do
    m = MonadState.get()
    assert {:right, 5} == Undetermined.run(State.eval(Undetermined.run(m, :state_t), 5), :either)
  end

  @tag timeout: 1000
  test "put" do
    m = MonadState.put(10)
    assert {:right, 10} == Undetermined.run(State.exec(Undetermined.run(m, :state_t), 5), :either)
  end
end
