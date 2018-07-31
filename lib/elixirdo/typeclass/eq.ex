defmodule Elixirdo.Typeclass.Eq do
  use Elixirdo.Base

  defmacro __using__(opts) do
    quote do
      alias Elixirdo.Typeclass.Eq
      unquote_splicing(__using_import__(opts))
    end
  end

  defclass eq(a) do
    def equal(x: a, y: a) :: boolean() do
      not non_equal(x, y, a)
    end

    def non_equal(x: a, y: a) :: boolean() do
      not equal(x, y, a)
    end
  end
end
