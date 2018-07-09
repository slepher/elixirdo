defmodule Elixirdo.Typeclass.Monad.Trans do
  use Elixirdo.Base

  defmacro __using__(opts) do
    import_typeclass = Keyword.get(opts, :import_typeclass, false)

    quoted_import =
      case import_typeclass do
        true ->
          [
            quote do
              import_typeclass MonadTrans.monad_trans()
            end
          ]

        false ->
          []
      end

    quote do
      alias Elixirdo.Typeclass.Monad.Trans, as: MonadTrans
      unquote_splicing(quoted_import)
    end
  end

  defclass monad_trans(t) do
    def lift(m(a)) :: t(m, a), m: monad
  end
end
