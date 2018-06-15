defmodule Elixirdo.Typeclass.Monad.MonadWriter do
  use Elixirdo.Base
  alias Elixirdo.Typeclass.Monad

  defmacro __using__(_) do
    quote do
      alias Elixirdo.Typeclass.Monad.MonadWriter
      import_typeclass MonadWriter.monad_writer()
    end
  end


  defclass monad_writer(m, m: monad) do
    def writer({a, w}) :: m

    def tell(w) :: m

    def listen(m(a)) :: m({a, w})

    def pass(m({a, (w -> w)})) :: m(a)
  end

  def listens(f, monad_writer_a, m) do
    nf = fn {a, w} -> {a, f.(w)} end
    Monad.lift_m(nf, listen(monad_writer_a, m), m)
  end

  def censor(f, monad_writer_a, m) do
    pass(Monad.lift_m(fn a -> {a, f} end, monad_writer_a, m), m)
  end
end
