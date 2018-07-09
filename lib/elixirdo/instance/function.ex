defmodule Elixirdo.Instance.Function do
  use Elixirdo.Base

  use Elixirdo.Typeclass.Monad, import_typeclasses: true
  use Elixirdo.Expand

  deftype function(r, a) :: (r -> a)

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

  definstance monad(function(r)) do
    def bind(fa, k_fb) do
      fn r -> k_fb.(fa.(r)).(r) end
    end
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
