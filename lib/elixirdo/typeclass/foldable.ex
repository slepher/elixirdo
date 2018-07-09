defmodule Elixirdo.Typeclass.Foldable do

  use Elixirdo.Base

  defmacro __using__(opts) do
    quote do
      alias Elixirdo.Typeclass.Foldable
      unquote_splicing(__using_import__(opts))
    end
  end

  defclass foldable t do
    def foldMap((a -> m), t) :: m
  end
end
