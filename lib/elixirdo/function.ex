defmodule Elixirdo.Function do
  use Elixirdo.Base

  import Elixirdo.Typeclass.Functor, only: [functor: 0]
  import Elixirdo.Typeclass.Applicative, only: [applicative: 0]

  deftype(function(r, a) :: (r -> a))

  definstance functor(function(r)) do
    def fmap(f, r) do
      fn a ->
        f.(r.(a))
      end
    end
  end

  definstance applicative(function(r)) do
    def pure(a) do
      fn _ -> a end
    end

    def ap(reader_f, reader_a) do
      fn r ->
        f = reader_f.(r)
        a = reader_a.(r)
        f.(a)
      end
    end
  end

  def unquote(:"<$")(b, fa) do
    Kernel.apply(Functor, :"default_<$", [b, fa, :function])
  end

  def unquote(:"<*>")(ff, fa) do
    fn r -> ff.(r).(fa.(r)) end
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

  def compose(f, g) do
    fn x -> f.(g.(x)) end
  end
end
