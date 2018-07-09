defmodule Elixirdo.Typeclass.Monad.Writer do
  use Elixirdo.Base.Typeclass
  use Elixirdo.Typeclass.Monad.Trans

  alias Elixirdo.Typeclass.Monad

  defmacro __using__(opts) do
    quote do
      use Elixirdo.Typeclass.Monad, unquote(opts)
      alias Elixirdo.Typeclass.Monad.Writer, as: MonadWriter
      unquote_splicing(__using_import__(opts))
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

  def lift_writer({a, w}, monad_writer, monad_trans) do
    MonadTrans.lift(writer({a, w}, monad_writer), monad_trans)
  end

  def lift_tell(w, monad_writer, monad_trans) do
    MonadTrans.lift(tell(w, monad_writer), monad_trans)
  end

end
