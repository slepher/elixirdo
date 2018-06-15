defmodule Elixirdo.Typeclass.Foldable do

  use Elixirdo.Base

  defmacro __using__(_) do
    quote do
      alias Elixirdo.Typeclass.Foldable
      import_typeclass Foldable.foldable()
    end
  end

  defclass foldable t do
    def foldMap((a -> m), t) :: m
  end
end
