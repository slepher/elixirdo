defmodule Elixirdo.Typeclass.Monad.State do
  use Elixirdo.Base.Typeclass
  use Elixirdo.Typeclass.Monad
  use Elixirdo.Typeclass.Monad.Trans

  defmacro __using__(opts) do
    import_typeclass = Keyword.get(opts, :import_typeclass, false)

    quoted_import =
      case import_typeclass do
        true ->
          [
            quote do
              import_typeclass MonadState.monad_state()
            end
          ]

        false ->
          []
      end

    quote do
      alias Elixirdo.Typeclass.Monad.State, as: MonadState
      unquote_splicing(quoted_import)
    end
  end

  defclass monad_state(m, m: monad) do
    def get() :: m(s) do
      state(fn s -> {s, s} end, m)
    end

    def put(state: s) :: m(:ok) do
      state(fn _ -> {:ok, state} end, m)
    end

    def state(f: (s -> {a, s})) :: m(a) do
      monad m do
        s <- get(m)
        {a, ns} = f.(s)
        put(ns, m)
        Monad.return(a, m)
      end
    end
  end

  def lift_get(monad_state, monad_trans) do
    MonadTrans.lift(get(monad_state), monad_trans)
  end

  def lift_put(s, monad_state, monad_trans) do
    MonadTrans.lift(put(s, monad_state), monad_trans)
  end

  def lift_state(f, monad_state, monad_trans) do
    MonadTrans.lift(state(f, monad_state), monad_trans)
  end
end
