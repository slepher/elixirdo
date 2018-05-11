defmodule Elixirdo.Expand do
  defmacro __using__(_) do
    quote do
      import Elixirdo.Expand, only: [expand: 1]
    end
  end

  defmacro expand(do: block) do
    line = __CALLER__.line
    file = __CALLER__.file |> Path.relative_to_cwd()
    IO.puts file <> ":" <> Integer.to_string(line)
    expanded_block = block |> Macro.expand(__CALLER__)
    expanded_block |> Macro.to_string |> IO.puts
    expanded_block
  end

end
