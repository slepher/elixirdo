defmodule Elixirdo.Notation.Do do

  defmacro __using__(_) do
    quote do
      import Elixirdo.Notation.Do, only: [monad: 2]
    end
  end

  defmacro monad(typeclass, do: body) do
    [h | t] = Enum.reverse(body)

    List.foldl(t, h, fn
      continue, {:let, _, [{:=, _, [assign, value]}]} ->
        quote do: unquote(value) |> (fn unquote(assign) -> unquote(continue) end).()

      continue, {:<-, _, [assign, value]} ->
        quote do
          Elixirdo.Typeclass.Monad.bind(unquote(value), fn unquote(assign) -> unquote(continue) end, unquote(typeclass))
        end

      continue, value ->
        quote do
          Elixirdo.Typeclass.Monad.bind(unquote(value), fn _ -> unquote(continue) end, unquote(typeclass))
        end
    end)
  end

end
