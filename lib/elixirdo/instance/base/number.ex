defmodule Elixirdo.Instance.Base.Number do
  use Elixirdo.Base

  deftype anonymous_string() :: number(), as: :number

  use Elixirdo.Typeclass.Ord, import_typeclasses: true

  definstance eq(number()) do
    def eq(number_a, number_b) do
      number_a == number_b
    end
  end

  definstance ord(number()) do
    def compare(number_a, number_b) do
      cond do
        number_a == number_b ->
          :eq

        number_a < number_b ->
          :lt

        number_a > number_b ->
          :gt
      end
    end
  end
end
