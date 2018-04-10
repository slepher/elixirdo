defmodule Elixirdo.Typeclass do

  def type({:just, _a}) do
    :maybe
  end

  def type(:nothing) do
    :maybe
  end

  def type(_type) do
    :undefined
  end

  def is_typeclass(:functor) do
    true
  end

  def is_typeclass(:applicative) do
    true
  end

  def is_typeclass(:monad) do 
    true
  end

  def is_typeclass(_a) do
    false
  end

  def module(:maybe, :functor) do
    Elixirdo.Maybe
  end

  def module(:maybe, :applicative) do
    Elixirdo.Maybe
  end

  def module(:maybe, :monad) do
    Elixirdo.Maybe
  end

  def module(type, typeclass) do
    :erlang.exit({:unregisted_module, {type, typeclass}})
  end
end
