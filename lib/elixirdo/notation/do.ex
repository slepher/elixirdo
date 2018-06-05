defmodule Elixirdo.Notation.Do do
  defmacro __using__(_) do
    quote do
      import Elixirdo.Notation.Do, only: [monad: 2]
    end
  end

  def normalize({:__block__, _, inner}), do: inner
  def normalize(single) when is_list(single), do: [single]
  def normalize(plain), do: List.wrap(plain)

  defmacro monad(typeclass, do: body) do
    [h | t] = body |> normalize |> Enum.reverse

    Enum.reduce(t, h, fn
      {:let, _, [{:=, _, [assign, value]}]}, continue ->
        quote do: unquote(value) |> (fn unquote(assign) -> unquote(continue) end).()

      {:<-, _, [assign, value]}, continue ->

        quote do
          Elixirdo.Typeclass.Monad.bind(
            unquote(value),
            fn unquote(assign) -> unquote(continue) end,
            unquote(typeclass)
          )
        end

      value, continue ->
        quote do
          Elixirdo.Typeclass.Monad.bind(
            unquote(value),
            fn _ -> unquote(continue) end,
            unquote(typeclass)
          )
        end
    end)
  end
end
