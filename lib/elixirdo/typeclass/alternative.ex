defmodule Elixirdo.Typeclass.Alternative do
  use Elixirdo.Base

  defmacro __using__(opts) do
    quote do
      use Elixirdo.Typeclass.Functor, unquote(opts)
      alias Elixirdo.Typeclass.Applicative
      unquote_splicing(__using_import__(opts))
    end
  end

  defclass alternative(f, f: applicative) do
    def empty() :: f
    def append(f, f) :: f
  end
end
