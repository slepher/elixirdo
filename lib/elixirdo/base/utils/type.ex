defmodule Elixirdo.Base.Utils.Type do

  alias Elixirdo.Base.Utils.Type

  defstruct [:type, :typeclasses]

  def typeclasses(types) do
    :lists.foldl(
      fn %Type{typeclasses: typeclasses}, acc ->
        :ordsets.union(typeclasses, acc)
      end, :ordsets.new(), types)
  end

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
end
