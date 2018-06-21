defmodule Elixirdo.Typeclass.Monad.MonadCont do

  use Elixirdo.Base
  use Elixirdo.Expand

  defmacro __using__(_) do
    quote do
      alias Elixirdo.Typeclass.Monad.MonadCont
      import_typeclass MonadCont.monad_cont
    end
  end

  defclass monad_cont m do
    def callCC( ((a -> m(b)) -> m(a)) ) :: m(b)
  end
end
