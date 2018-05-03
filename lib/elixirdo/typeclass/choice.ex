defmodule Elixirdo.Typeclass.Choice do
  alias Elixirdo.Base.Undetermined
  alias Elixirdo.Base.Generated

  def right(uab, uchoice \\ :choice) do
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
