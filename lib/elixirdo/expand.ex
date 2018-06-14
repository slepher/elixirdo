defmodule Elixirdo.Expand do
  defmacro __using__(_) do
    quote do
      import Elixirdo.Expand, only: [expand: 1]
    end
  end

  defmacro expand(do: block) do
    expanded_block = block |> Macro.expand(__CALLER__)
    expanded_block |> Macro.to_string() |> add_tab() |> append_env(__CALLER__) |> IO.puts()
    expanded_block
  end

  def append_env(string, caller) do
    line = caller.line
    file = caller.file |> Path.relative_to_cwd()
    file <> ":" <> Integer.to_string(line) <> "\n" <> string
  end

  def add_tab(string) do
    lines = String.split(string, "\n")
    lines = :lists.map(fn line -> "  " <> line end, lines)
    Enum.join(lines, "\n")
  end
end
