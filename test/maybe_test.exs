defmodule MaybeTest do
  use ExUnit.Case
  doctest Elixirdo.Maybe

  test "greets the world" do
    f = fn a -> a * 2 end
    assert {:just, 2} == Elixirdo.Functor.fmap(f, {:just, 1})
    assert :nothing == Elixirdo.Functor.fmap(f, :nothing)
  end
end
