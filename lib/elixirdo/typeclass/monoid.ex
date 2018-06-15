defmodule Elixirdo.Typeclass.Monoid do

  use Elixirdo.Base

  defmacro __using__(_) do
    quote do
      alias Elixirdo.Typeclass.Monoid
      import_typeclass Monoid.monoid
    end
  end

  defclass monoid m do
    def empty() :: m

    def append(m, m) :: m
  end
end
