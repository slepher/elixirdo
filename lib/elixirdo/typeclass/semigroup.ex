defmodule Elixirdo.Typeclass.Semigroup do
  use Elixirdo.Base

  defmacro __using__(opts) do
    quote do
      alias Elixirdo.Typeclass.Semigroup
      unquote_splicing(__using_import__(opts))
    end
  end

  defclass semigroup(m) do
    def sappend(m, m) :: m
  end

end
