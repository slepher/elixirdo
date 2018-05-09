defmodule Elixirdo.Base do
  defmacro __using__(_) do
    quote do
      use Elixirdo.Base.Typeclass
      use Elixirdo.Base.Instance
      use Elixirdo.Base.Type
    end
  end
end
