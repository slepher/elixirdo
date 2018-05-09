defmodule Elixirdo.Maybe do
  use Elixirdo.Base
  alias Elixirdo.Base.Undetermined
  import Elixirdo.Typeclass.Functor, only: [functor: 0]
  import Elixirdo.Typeclass.Applicative, only: [applicative: 0]

  deftype maybe(a) :: {:just, a} | :nothing

  definstance functor maybe, at: Elixirdo.Typeclass.Functor do
    def fmap(f, {:just, x}) do
      {:just, f.(x)}
    end

    def fmap(_f, :nothing) do
      :nothing
    end
  end

  definstance applicative maybe, at: Elixirdo.Typeclass.Applicative  do
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

  def run(%Undetermined{} = ua) do
    Undetermined.run(ua, :maybe)
  end

  def run(maybe) do
    maybe
  end
end
