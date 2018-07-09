defmodule Elixirdo.Typeclass.Monad.Plus do

  use Elixirdo.Base
  use Elixirdo.Typeclass.Monad

  defmacro __using__(opts) do
    import_typeclass = Keyword.get(opts, :import_typeclass, false)

    quoted_import =
      case import_typeclass do
        true ->
          [
            quote do
              import_typeclass MonadPlus.monad_plus()
            end
          ]

        false ->
          []
      end

    quote do
      alias Elixirdo.Typeclass.Monad.Plus, as: MonadPlus
      unquote_splicing(quoted_import)
    end
  end

  defclass monad_plus(m, m: monad) do
    def mzero() :: m(a)

    def mplus(m(a), m(a)) :: m(a)
  end

  def guard(cond) do
    guard(cond, :monad_plus)
  end

  def guard(true, m) do
    Monad.return({}, m)
  end

  def guard(false, m) do
    mzero(m)
  end
end
