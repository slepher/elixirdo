defmodule Elixirdo.Typeclass.Monad.MonadState do

  use Elixirdo.Base
  use Elixirdo.Notation.Do
  alias Elixirdo.Typeclass.Monad

  defmacro __using__(_) do
    quote do
      alias Elixirdo.Typeclass.Monad.MonadState
      import_typeclass MonadState.monad_state
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
end
