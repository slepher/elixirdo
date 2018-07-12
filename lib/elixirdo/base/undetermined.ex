defmodule Elixirdo.Base.Undetermined do
  alias Elixirdo.Base.Undetermined
  alias Elixirdo.Base.Generated

  defstruct [:required_typeclass, :typeclass, :inner_function]

  def new(f, typeclass) do
    new(f, typeclass, typeclass)
  end

  def new(f, required_typeclass, typeclass) do
    case(Generated.is_typeclass(required_typeclass)) do
      true ->
        %Undetermined{required_typeclass: required_typeclass, typeclass: typeclass, inner_function: f}
      false ->
        f.(required_typeclass)
    end
  end

  def type(undetermined_a, typeclass) do
    case guess_type([undetermined_a], typeclass) do
      nil -> typeclass
      type -> type
    end
  end

  def run(%Undetermined{inner_function: f} = undetermined_a, typeclass) do
    case Generated.is_typeclass(typeclass) do
      true -> undetermined_a
      false -> f.(typeclass)
    end
  end

  def run(a, _typeclass) do
    a
  end

  def map(f, undetermined_a, typeclass) do
    map(f, undetermined_a, typeclass, typeclass)
  end

  def map(f, undetermined_a, typeclass, return_type) do
    map_list(fn [a], type -> f.(a, type) end, [undetermined_a], typeclass, return_type)
  end

  def map_list(f, values, typeclass, return_type, new \\ true) do
    case guess_type(values, typeclass) do
      nil ->
        case new do
          true ->
            new(fn type -> map_list(f, values, type, return_type) end, typeclass, return_type)

          false ->
            f.(values, typeclass)
        end

      type ->
        f.(map_type(values, type), type)
    end
  end

  def guess_type(as, type_or_typeclass) do
    case Generated.is_typeclass(type_or_typeclass) do
      true ->
        guess_type(as)

      false ->
        type_or_typeclass
    end
  end

  defp guess_type([%Undetermined{} | t]) do
    guess_type(t)
  end

  defp guess_type([h | _]) do
    Generated.type(h)
  end

  defp guess_type([]) do
    nil
  end

  defp map_type(values, type) do
    Enum.map(values, fn value -> run(value, type) end)
  end
end
