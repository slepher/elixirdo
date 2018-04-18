defmodule MaybeTest do
  use ExUnit.Case
  alias Elixirdo.Typeclass.Functor
  doctest Elixirdo.Maybe

  @tag timeout: 1000
  test "fmap" do
    f = fn a -> a * 2 end
    assert {:just, 2} == Functor.fmap(f, {:just, 1})
    assert :nothing == Functor.fmap(f, :nothing)
  end
end
