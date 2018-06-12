defmodule Elixirdo.Instance.Maybe do
  use Elixirdo.Base
  use Elixirdo.Expand
  alias Elixirdo.Base.Undetermined

  use Elixirdo.Typeclass.Monad

  deftype maybe(a) :: {:just, a} | :nothing

  definstance functor(maybe) do
    def fmap(f, {:just, x}) do
      {:just, f.(x)}
    end

    def fmap(_f, :nothing) do
      :nothing
    end
  end

  definstance applicative(maybe) do
    def pure(a) do
      {:just, a}
    end

    def ap(:nothing, _) do
      :nothing
    end

    def ap(_, :nothing) do
      :nothing
    end

    def ap({:just, f}, {:just, a}) do
      {:just, f.(a)}
    end

  end

  definstance monad(maybe) do
    def return(a) do
      {:just, a}
    end

    def bind({:just, x}, fun) do
      fun.(x)
    end

    def bind(:nothing, _fun) do
      :nothing
    end
  end

  def unquote(:">>")(ma, mb) do
    Kernel.apply(:monad, :"default_>>", [ma, mb, __MODULE__])
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

  def run(%Undetermined{} = ua) do
    Undetermined.run(ua, :maybe)
  end

  def run(maybe) do
    maybe
  end
end
