defmodule Elixirdo.Typeclass.Monad.Reader do
  use Elixirdo.Base.Typeclass
  use Elixirdo.Typeclass.Monad.Trans

  alias Elixirdo.Typeclass.Monad

  defmacro __using__(opts) do
    quote do
      use Elixirdo.Typeclass.Monad, unquote(opts)
      alias Elixirdo.Typeclass.Monad.Reader, as: MonadReader
      unquote_splicing(__using_import__(opts))
    end
  end

  defclass monad_reader(m, m: monad) do
    def ask() :: m do
      reader(fn a -> a end, m)
    end

    def reader(f: (r -> r)) :: m(r) do
      Monad.lift_m(f, ask(m), m)
    end

    def local((r -> r), m(r)) :: m(r)
  end

  def lift_ask(monad_reader, monad_trans) do
    MonadTrans.lift(ask(monad_reader), monad_trans)
  end

  def lift_reader(f, monad_reader, monad_trans) do
    MonadTrans.lift(reader(f, monad_reader), monad_trans)
  end

end
