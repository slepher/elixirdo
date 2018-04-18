defmodule Elixirdo.Notation do
  defmacro monad(type, do: body) do
    [h | t] = Enum.reverse(body)

    List.foldl(t, h, fn
      continue, {:let, _, [{:=, _, [assign, value]}]} ->
        quote do: unquote(value) |> (fn unquote(assign) -> unquote(continue) end).()

      continue, {:<-, _, [assign, value]} ->
        quote do
          bind(unquote(value), fn unquote(assign) -> unquote(continue) end, unquote(type))
        end

      continue, value ->
        quote do
          bind(unquote(value), fn _ -> unquote(continue) end, unquote(type))
        end
    end)
  end
end
