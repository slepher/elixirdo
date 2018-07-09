defmodule Elixirdo.Typeclass.Monad.Fail do
  use Elixirdo.Base
  use Elixirdo.Typeclass.Monad.Trans

  defmacro __using__(opts) do
    import_typeclass = Keyword.get(opts, :import_typeclass, false)

    quoted_import =
      case import_typeclass do
        true ->
          [
            quote do
              import_typeclass MonadFail.monad_fail()
            end
          ]

        false ->
          []
      end

    quote do
      alias Elixirdo.Typeclass.Monad.Fail, as: MonadFail
      unquote_splicing(quoted_import)
    end
  end

  defclass monad_fail(m, m: monad) do
    def fail(e) :: m
  end

  def lift_fail(e, monad, monad_trans) do
    MonadTrans.lift(fail(e, monad), monad_trans)
  end
end
