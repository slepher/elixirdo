defmodule ListTest do
  use ExUnit.Case
  use Elixirdo.Typeclass.Monad, import_typeclass: true
  doctest Elixirdo.Instance.List

  alias Elixirdo.Instance.Maybe

  alias Elixirdo.Typeclass.Traversable

  @moduletag timeout: 1000

  test "fmap" do
    list_a = [1, 2, 3]
    list_b = [2, 3, 4]
    list_c = Functor.fmap(&(&1 + 1), list_a)
    assert list_b == list_c
  end

  test "pure" do
    list_a = [1]
    list_b = Applicative.pure(1, :list)
    assert list_a == list_b
  end

  test "ap" do
    list_a = [3, 8]
    list_b = [&(&1 + 1), &(&1 + 3)]
    list_c = [4, 9, 6, 11]
    list_d = list_b |> Applicative.ap(list_a)
    assert list_c == list_d
  end

  test "return" do
    list_a = [1]
    list_b = Monad.return(1, :list)
    assert list_a == list_b
  end

  test "bind" do
    list_a = [3, 8]
    list_b = [4, 6, 9, 11]

    list_c =
      monad :list do
        a <- list_a
        [a + 1, a + 3]
      end

    assert list_b == list_c
  end

  test "traverse" do
    list_a = [3, 8]
    f = fn a -> Applicative.pure(a + 1, :maybe) end
    list_b = Traversable.traverse(f, list_a)
    list_c =  Maybe.Just.new([4, 9])
    assert list_b == list_c
  end

  test "sequence_a" do
    list_a = [Maybe.Just.new(3), Maybe.Just.new(8)]
    list_b = Traversable.sequence_a(list_a)
    maybe_c = Maybe.Just.new([3, 8])
    list_d = [Maybe.Just.new(3), Maybe.Nothing.new()]
    list_e = Traversable.sequence_a(list_d)
    maybe_f = Maybe.Nothing.new()
    assert list_b == maybe_c
    assert list_e == maybe_f
  end
end
