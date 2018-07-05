defmodule Elixirdo.Typeclass.Monoid do

  use Elixirdo.Base

  defmacro __using__(_) do
    quote do
      alias Elixirdo.Typeclass.Monoid
      import_typeclass Monoid.monoid
    end
  end

  defclass monoid m do
    def mempty() :: m

    def mappend(m, m) :: m
  end
end
