defmodule Elixirdo.Maybe do
  def fmap(:nothing, f) do
    :nothing
  end

  def fmap({:just, value}, f) do
    {:just, f.(value)}
  end
end

defimpl Elixirdo.Functor, for: Elixirdo.Maybe do
  def fmap(value, f), do: Elixirdo.Maybe.fmap(value, f)
end
