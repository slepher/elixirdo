defmodule Elixirdo.Typeclass.Monad.Trans do
  use Elixirdo.Base

  defmacro __using__(opts) do
    quote do
      use Elixirdo.Typeclass.Monad, unquote(opts)
      alias Elixirdo.Typeclass.Monad.Trans, as: MonadTrans
      unquote_splicing(__using_import__(opts))
    end
  end

  defclass monad_trans(t) do
    def lift(m(a)) :: t(m, a), m: monad
  end
end
