defmodule Elixirdo.Typeclass.Functor do
  use Elixirdo.Base
  use Elixirdo.Expand

  defmacro __using__(opts) do
    import_typeclass = Keyword.get(opts, :import_typeclass, false)

    quoted_import =
      case import_typeclass do
        true ->
          [quote(do: import_typeclass(Functor.functor()))]

        false ->
          []
      end

    quote do
      alias Elixirdo.Typeclass.Functor
      unquote_splicing(quoted_import)
    end
  end

  defclass functor(f) do
    def fmap((a -> b), f(a)) :: f(b)
  end
end
