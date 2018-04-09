defmodule Elixirdo.Function do

  alias Elixirdo.Functor
  alias Elixirdo.Applicative
  alias Elixirdo.Monad
  
  def fmap(f, fa) do
    Kernel.apply(__MODULE__, :., [f, fa])
  end

  def unquote(:"<$")(b, fa) do
    Kernel.apply(Functor, :"default_<$", [b, fa, :function])
  end

  def unquote(:"<*>")(ff, fa) do
    fn r -> ff.(r).(fa.(r)) end
  end

  def pure(a) do
    const(a)
  end

  def lift_a2(f, fa, fb) do
    Applicative.default_lift_a2(f, fa, fb, __MODULE__)
  end

  def unquote(:"*>")(fa, fb) do
    Kernel.apply(Applicative, :"default_*>", [fa, fb, :function])
  end

  def unquote(:"<*")(rTA, rTB) do
    Kernel.apply(Applicative, :"default_<*", [rTA, rTB, :function])
  end

  def unquote(:">>=")(fa, kFB) do
    fn x -> kFB.(fa.(x)).(x) end
  end

  def unquote(:">>")(fa, fB) do
    Kernel.apply(Monad, :"default_>>", [fa, fB, :function])
  end

  def return(a) do
    Monad.default_return(a, :function)
  end

  def ask() do
    id()
  end

  def local(f, fI) do
    Kernel.apply(__MODULE__, :., [fI, f])
  end

  def reader(f) do
    id(f)
  end

  def run_nargs() do
    1
  end

  def run_m(f, [a]) do
    f.(a)
  end

  def unquote(:.)(f, g) do
    fn x -> f.(g.(x)) end
  end

  def const(a) do
    fn _r -> a end
  end

  def id() do
    fn a -> a end
  end

  def id(a) do
    a
  end

end
