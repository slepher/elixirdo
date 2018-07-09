defmodule Elixirdo.Typeclass.Monad.Cont do
  use Elixirdo.Base

  defmacro __using__(opts) do
    import_typeclass = Keyword.get(opts, :import_typeclass, false)

    quoted_import =
      case import_typeclass do
        true ->
          [quote(do: import_typeclass(MonadCont.monad_cont()))]
        false ->
          []
      end

    quote do
      alias Elixirdo.Typeclass.Monad.Cont, as: MonadCont
      unquote_splicing(quoted_import)
    end
  end

  defclass monad_cont(m) do
    def callCC(((a -> m(b)) -> m(a))) :: m(b)
  end
end
