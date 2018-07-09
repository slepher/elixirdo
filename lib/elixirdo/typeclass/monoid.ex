defmodule Elixirdo.Typeclass.Monoid do
  use Elixirdo.Base
  use Elixirdo.Expand

  defmacro __using__(opts) do
    quote do
      alias Elixirdo.Typeclass.Monoid
      unquote_splicing(__using_import__(opts))
    end
  end

  defclass monoid(m) do
    def mempty() :: m

    def mappend(m, m) :: m
  end
end
