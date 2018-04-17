defmodule Elixirdo.Maybe do

  alias Elixirdo.Applicative
  alias Elixirdo.Monad
  alias Elixirdo.Undetermined

  def fmap(f, {:just, x}) do
    {:just, f.(x)}
  end

  def fmap(f, {:just, x}, :maybe) do
    {:just, f.(x)}
  end

  def fmap(_f, :nothing, :maybe) do
    :nothing
  end

  def unquote(:"<$")(b, ma) do
    Kernel.apply(:functor, :"default_<$", [b, ma, __MODULE__])
  end

  def pure(a, _ \\ :maybe) do
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

  def lift_a2(f, ma, mb, _ \\ :maybe) do
    Applicative.default_lift_a2(f, ma, mb, :maybe)
  end

  def unquote(:"*>")(ma, mb) do
    Kernel.apply(Applicative, :"default_*>", [ma, mb, __MODULE__])
  end

  def unquote(:"<*")(ma, mb) do
    Kernel.apply(Applicative, :"default_<*", [ma, mb, __MODULE__])
  end

  def bind(ma, kmb), do: bind(ma, kmb, :maybe)


  def bind({:just, x}, fun, :maybe) do
    fun.(x)
  end

  def bind(:nothing, _fun, :maybe) do
    :nothing
  end

  def unquote(:">>")(ma, mb) do
    Kernel.apply(:monad, :"default_>>", [ma, mb, __MODULE__])
  end

  def return(a, _ \\ :maybe) do
    Monad.default_return(a, __MODULE__)
  end

  def fail(_e, _ \\ :maybe) do
    :nothing
  end

  def empty(_ \\ :maybe) do
    :nothing
  end

  def unquote(:<|>)(:nothing, mb) do
    mb
  end

  def unquote(:<|>)(ma, _mb) do
    ma
  end

  def mzero(_ \\ :maybe) do
    empty(:maybe)
  end

  def mplus(ma, mb, _ \\ :maybe) do
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
