defmodule Elixirdo.Typeclass.Monoid do
  use Elixirdo.Base
  use Elixirdo.Expand

  defmacro __using__(opts) do
    import_typeclass = Keyword.get(opts, :import_typeclass, false)

    quoted_import =
      case import_typeclass do
        true ->
          [quote(do: import_typeclass Monoid.monoid())]

        false ->
          []
      end

    quote do
      alias Elixirdo.Typeclass.Monoid
      unquote_splicing(quoted_import)
    end
  end

  defclass monoid(m) do
    def mempty() :: m

    def mappend(m, m) :: m
  end
end
