defmodule ElixirdoTest do
  use ExUnit.Case
  doctest Elixirdo

  test "greets the world" do
    assert Elixirdo.hello() == :world
  end
end
