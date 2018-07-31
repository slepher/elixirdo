defmodule Elixirdo.Instance.Base.String do
  use Elixirdo.Base

  deftype anonymous_string() :: String.t(), as: :string

  use Elixirdo.Typeclass.Ord, import_typeclasses: true

  definstance eq(string()) do
    def eq(string_a, string_b) do
      string_a == string_b
    end
  end

  definstance ord(string()) do
    def compare(string_a, string_b) do
      cond do
        string_a == string_b ->
          :eq
        string_a < string_b ->
          :lt
        string_a > string_b ->
          :gt
      end
    end
  end

end
