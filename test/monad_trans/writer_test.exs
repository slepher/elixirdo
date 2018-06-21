defmodule MonadTrans.WriterTest do
  use ExUnit.Case
  use Elixirdo.Typeclass.Monad

  alias Elixirdo.Instance.MonadTrans.Writer

  doctest Elixirdo.Instance.MonadTrans.Writer

  use Elixirdo.Expand
  @moduletag timeout: 1000

  test "fmap" do
    writer_t_a = Writer.new_writer_t({:just, {5, [:hello]}})
    writer_t_b = Writer.new_writer_t({:just, {10, [:hello]}})

    writer_t_c = Functor.fmap(fn a -> a * 2 end, writer_t_a)
    assert writer_t_b == writer_t_c
  end

  test "ap" do
    writer_t_f = Writer.new_writer_t({:just, {fn a -> a * 2 end, [:hello]}})
    writer_t_a = Writer.new_writer_t({:just, {5, [:world]}})

    writer_t_b = Writer.new_writer_t({:just, {10, [:hello]}})


  end
end
