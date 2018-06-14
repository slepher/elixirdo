defmodule Elixirdo.Typeclass.Monad do
  use Elixirdo.Base
  use Elixirdo.Expand

  alias Elixirdo.Typeclass.Applicative

  @type m(_m, _a) :: any()

  defmacro __using__(_) do
    quote do
      use Elixirdo.Typeclass.Applicative
      use Elixirdo.Notation.Do
      alias Elixirdo.Typeclass.Monad
      import_typeclass Monad.monad()
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
  end

  def join(mma, monad \\ :monad) do
    bind(mma, fn ma -> ma end, monad)
  end

  def lift_m(f, ma, monad \\ :monad) do
    bind(ma, fn a -> return(f.(a), monad) end, monad)
  end
end
