defmodule MonadTrans.StateTest do
  use ExUnit.Case
  use Elixirdo.Typeclass.Monad.State
  alias Elixirdo.Instance.MonadTrans.State
  alias Elixirdo.Base.Undetermined
  alias Elixirdo.Instance.Either

  doctest State

  @tag timeout: 1000
  test "get" do
    m = MonadState.get()
    assert Either.Right.new(5) == Undetermined.run(State.eval(Undetermined.run(m, :state_t), 5), :either)
  end

  @tag timeout: 1000
  test "put" do
    m = MonadState.put(10)
    assert Either.Right.new(10) == Undetermined.run(State.exec(Undetermined.run(m, :state_t), 5), :either)
  end
end
