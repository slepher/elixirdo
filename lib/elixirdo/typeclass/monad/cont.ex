defmodule Elixirdo.Typeclass.Monad.Cont do
  use Elixirdo.Base

  defmacro __using__(opts) do
    quote do
      use Elixirdo.Typeclass.Monad, unquote(opts)
      alias Elixirdo.Typeclass.Monad.Cont, as: MonadCont
      unquote_splicing(__using_import__(opts))
    end
  end

  defclass monad_cont(m) do
    def callCC(((a -> m(b)) -> m(a))) :: m(b)
  end
end
