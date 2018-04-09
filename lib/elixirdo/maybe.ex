defmodule Elixirdo.Maybe do

  alias Elixirdo.Applicative
  alias Elixirdo.Monad
  alias Elixirdo.Undetermined

  def fmap(f, {:just, x}) do
    {:just, f.(x)}
  end

  def fmap(_f, :nothing) do
    :nothing
  end

  def unquote(:"<$")(b, ma) do
    Kernel.apply(:functor, :"default_<$", [b, ma, __MODULE__])
  end

  def pure(a) do
    {:just, a}
  end

  def unquote(:"<*>")(:nothing, _) do
    :nothing
  end

  def unquote(:"<*>")(_, :nothing) do
    :nothing
  end

  def unquote(:"<*>")({:just, f}, {:just, a}) do
    {:just, f.(a)}
  end

  def lift_a2(f, ma, mb) do
    Applicative.default_lift_a2(f, ma, mb, __MODULE__)
  end

  def unquote(:"*>")(ma, mb) do
    Kernel.apply(Applicative, :"default_*>", [ma, mb, __MODULE__])
  end

  def unquote(:"<*")(ma, mb) do
    Kernel.apply(Applicative, :"default_<*", [ma, mb, __MODULE__])
  end

  def unquote(:">>=")({:just, x}, fun) do
    fun.(x)
  end

  def unquote(:">>=")(:nothing, _fun) do
    :nothing
  end

  def unquote(:">>")(ma, mb) do
    Kernel.apply(:monad, :"default_>>", [ma, mb, __MODULE__])
  end

  def return(a) do
    Monad.default_return(a, __MODULE__)
  end

  def fail(_e) do
    :nothing
  end

  def empty() do
    :nothing
  end

  def unquote(:<|>)(:nothing, mb) do
    mb
  end

  def unquote(:<|>)(ma, _mb) do
    ma
  end

  def mzero() do
    empty()
  end

  def mplus(ma, mb) do
    Kernel.apply(__MODULE__, :<|>, [ma, mb])
  end

  def run_nargs() do
    0
  end

  def run_m(mA, []) do
    mA
  end

  def run(%Elixirdo.Undetermined{} = ua) do
    Undetermined.run(ua, __MODULE__)
  end

  def run(maybe) do
    maybe
  end

end
