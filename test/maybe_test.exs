defmodule MaybeTest do
  use ExUnit.Case
  doctest Elixirdo.Maybe

  test "greets the world" do
    f = fn a -> a * 2 end
    assert {:just, 2} == Elixirdo.Functor.fmap({:just, 1}, f)
    assert :nothing == Elixirdo.Functor.fmap(:nothing, f)
  end
end
