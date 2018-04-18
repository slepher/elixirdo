defmodule Elixirdo.Choice do
  alias Elixirdo.Undetermined
  alias Elixirdo.Typeclass.Generated

  def right(uab, uchoice) do
    Undetermined.map(
      fn choice, pab ->
        do_right(pab, choice)
      end,
      uab,
      uchoice
    )
  end

  def do_right(ab, choice) do
    module = Generated.module(choice, :choice)
    module.right(ab, choice)
  end
end
