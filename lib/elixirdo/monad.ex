defmodule Elixirdo.Monad do

  alias Elixirdo.Applicative
  alias Elixirdo.TypeclassTrans
  alias Elixirdo.Undetermined

  def unquote(:">>=")(uA, kUB, uMonad) do
    Undetermined.map(fn monad, mA ->
      kMB = fn a -> Undetermined.run(kUB.(a), monad) end
      func_do____(mA, kMB, monad)
    end, uA, uMonad)
  end

  def unquote(:">>")(uA, uB, uMonad) do
    Undetermined.map_pair(fn monad, mA, mB -> TypeclassTrans.apply(:">>", [mA, mB], monad, __MODULE__) end, uA, uB, uMonad)
  end

  def return(a, uMonad) do
    Undetermined.new(fn monad -> TypeclassTrans.apply(:return, [a], monad, __MODULE__) end, uMonad)
  end

  def unquote(:"default_>>")(mA, mB, monad) do
    func_do____(mA, fn _ -> mB end, monad)
  end

  def default_return(a, monad) do
    Applicative.pure(a, monad)
  end

  def bind(x, f, monad) do
    Kernel.apply(__MODULE__, :">>=", [x, f, monad])
  end

  def then(x, f, monad) do
    Kernel.apply(__MODULE__, :">>", [x, f, monad])
  end

  def join(mMA, monad) do
    bind(mMA, fn mA -> mA end, monad)
  end

  def lift_m(f, mA, monad) do
    :erlang.do(for(a <- mA, return(f.(a), :monad), into: [], do: monad))
  end

  def as(a, {t, m}) do
    MonadTrans.lift(as(a, m), {t, m})
  end

  def as(a, m) do
    return(a, m)
  end

  def id(monad) do
    as(fn a -> a end, monad)
  end

  def empty(monad) do
    as(:ok, monad)
  end

  def run(m, monad) do
    Applicative.ap(id(monad), m, :applicative)
  end

  defp func_do____(mA, kMB, monad) do
    TypeclassTrans.apply(:">>=", [mA, kMB], monad, __MODULE__)
  end

end
