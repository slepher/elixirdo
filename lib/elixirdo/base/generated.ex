defmodule Elixirdo.Base.Generated do

  def type({:just, _a}) do
    :maybe
  end

  def type(:nothing) do
    :maybe
  end

  def type(%Elixirdo.MaybeT{}) do
    :maybe_t
  end

  def type(function) when is_function(function) do
    :function
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

  def module(:function, :functor) do
    Elixirdo.Function
  end

  def module(:function, :applicative) do
    Elixirdo.Function
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

  def module(:maybe_t, :functor) do
    Elixirdo.MaybeT
  end

  def module(:maybe_t, :applicative) do
    Elixirdo.MaybeT
  end

  def module(:maybe_t, :monad) do
    Elixirdo.MaybeT
  end

  def module(:maybe_t, :monad_trans) do
    Elixirdo.MaybeT
  end

  def module({:maybe_t, _}, :functor) do
    Elixirdo.MaybeT
  end

  def module({:maybe_t, _}, :applicative) do
    Elixirdo.MaybeT
  end

  def module({:maybe_t, _}, :monad) do
    Elixirdo.MaybeT
  end

  def module({:maybe_t, _}, :monad_trans) do
    Elixirdo.MaybeT
  end

  def module(function, :profunctor) when is_function(function) do
    Elixirdo.Function
  end

  def module(function, :choice) when is_function(function) do
    Elixirdo.Function
  end


  def module(type, typeclass) do
    :erlang.exit({:unregisted_module, {type, typeclass}})
  end
end
