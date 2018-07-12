defmodule Elixirdo.Base.Utils.Type do

  alias Elixirdo.Base.Utils.Type

  defstruct [:type, :typeclasses]


  defmodule Function do
    defstruct [:arguments, :return]
  end

  defmodule Tuple do
    defstruct [:elements]
  end

  defmodule Map do
    defstruct [:map_pairs]
  end

  defmodule Typeclass do
    defstruct [:typeclass, :arguments, :arity]
  end

  def typeclasses(types) do
    :lists.foldl(
      fn %Type{typeclasses: typeclasses}, acc ->
        :ordsets.union(typeclasses, acc)
      end, :ordsets.new(), types)
  end

  def escape(%Type{type: type}, typeclasses) do
    escape(type, typeclasses)
  end

  def escape(%Function{arguments: arguments, return: return}, typeclasses) do
    %Function{arguments: Enum.map(arguments, &escape(&1, typeclasses)), return: escape(return, typeclasses)}
  end

  def escape(%Tuple{elements: elements}, typeclasses) do
    %Tuple{elements: Enum.map(elements, &escape(&1, typeclasses))}
  end

  def escape(%Map{map_pairs: map_pairs}, typeclasses) do
    %Map{map_pairs: Enum.map(map_pairs, fn {key, value} -> {key, escape(value, typeclasses)} end)}
  end

  def escape(%Typeclass{arguments: arguments}, typeclasses) do
    %Typeclass{arguments: Enum.map(arguments, &escape(&1, typeclasses))}
  end

  def escape(type_param, typeclasses) do
    case Keyword.get(typeclasses, type_param) do
      nil ->
        type_param
      typeclass ->
        typeclass
    end
  end

end
