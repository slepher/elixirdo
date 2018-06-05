defmodule Elixirdo.Typeclass.Monad.MonadReader do
  use Elixirdo.Base.Typeclass
  use Elixirdo.Expand
  alias Elixirdo.Typeclass.Monad

  defclass monad_reader(m, m: monad) do
    def ask() :: m do
      reader(fn a -> a end, m)
    end

    def reader(f: (r -> r)) :: m(r) do
      Monad.lift_m(f, ask(m), m)
    end

    def local((r -> r), m(r)) :: m(r)

  end
end
