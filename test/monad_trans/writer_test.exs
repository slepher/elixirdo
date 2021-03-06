defmodule MonadTrans.WriterTest do
  use ExUnit.Case
  use Elixirdo.Typeclass.Monad
  use Elixirdo.Instance.Maybe

  alias Elixirdo.Instance.MonadTrans.Writer, as: WriterT

  doctest Elixirdo.Instance.MonadTrans.Writer

  @moduletag timeout: 1000

  def writer_just(a, ws) do
    WriterT.new(Just.new({a, ws}))
  end

  test "fmap" do
    writer_t_a = writer_just(5, [:hello])
    writer_t_b = writer_just(10, [:hello])
    writer_t_c = Functor.fmap(fn a -> a * 2 end, writer_t_a)
    assert writer_t_b == writer_t_c
  end

  test "ap" do
    writer_t_f = writer_just(fn a -> a * 2 end, [:hello])
    writer_t_a = writer_just(5, [:world])
    writer_t_b = writer_just(10, [:hello, :world])
    writer_t_c = Applicative.ap(writer_t_f, writer_t_a)
    assert writer_t_b == writer_t_c
  end

  test "bind" do

  end
end
