defmodule Elixirdo.Typeclass.Monad do
  use Elixirdo.Base
  use Elixirdo.Expand

  alias Elixirdo.Typeclass.Applicative

  @type m(_m, _a) :: any()

  defmacro __using__(opts) do
    quote do
      use Elixirdo.Typeclass.Applicative, unquote(opts)
      use Elixirdo.Notation.Do
      alias Elixirdo.Typeclass.Monad
      unquote_splicing(__using_import__(opts))
    end
  end

  defclass monad(m, m: applicative) do
    def return(a: a) :: m(a) do
      Applicative.pure(a, m)
    end

    def bind(m(a), (a -> m(b))) :: m(b)

    def then(ma: m(a), mb: m(b)) :: m(b) do
      bind(ma, fn _ -> mb end, m)
    end

    law left_identity(a: a, f: (a -> m(b))) :: m(b) do
      return(a) |> bind(f) === f.(a)
    end

    law right_identity(m: m(a)) :: m(a) do
      m |> bind(&return/1) === m
    end

    law associativity(m: m(a), f: (a -> m(b)), g: (b -> m(c))) :: m(c) do
      m |> bind(f) |> bind(g) === m |> bind(fn a -> f.(a) |> bind(g) end)
    end
  end

  def join(mma, monad \\ :monad) do
    bind(mma, fn ma -> ma end, monad)
  end

  def lift_m(f, ma, monad \\ :monad) do
    bind(ma, fn a -> return(f.(a), monad) end, monad)
  end
end
