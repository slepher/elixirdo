defmodule Elixirdo.Base.Undetermined do
  alias Elixirdo.Base.Undetermined
  alias Elixirdo.Base.Generated

  defstruct [:typeclass, :inner_function]

  def new(f, typeclass) do
    case(Generated.is_typeclass(typeclass)) do
      true ->
        %Undetermined{typeclass: typeclass, inner_function: f}

      false ->
        f.(typeclass)
    end
  end

  def type(ua, typeclass) do
    check_type(fn _ma, type -> type end, ua, typeclass)
  end

  def run(ua, typeclass) do
    check_type(fn ma, _type -> ma end, ua, typeclass)
  end

  def check_type(f, ua, typeclass) do
    do_map(f, fn -> f.(ua, typeclass) end, ua, typeclass)
  end

  def map(f, ua, typeclass) do
    do_map(f, fn -> new(fn type -> map(f, ua, type) end, typeclass) end, ua, typeclass)
  end

  def do_map(f, fs, %Undetermined{inner_function: uf}, typeclass) do
    case(Generated.is_typeclass(typeclass)) do
      true ->
        fs.()

      false ->
        f.(uf.(typeclass), typeclass)
    end
  end

  def do_map(f, _fs, a, typeclass) do
    case(Generated.is_typeclass(typeclass)) do
      true ->
        type = Generated.type(a)
        f.(a, type)

      false ->
        f.(a, typeclass)
    end
  end

  def map_list(f, [], typeclass) do
    nf = fn type -> f.([], type) end
    new(nf, typeclass)
  end

  def map_list(f, values, typeclass) do
    case Generated.is_typeclass(typeclass) do
      true ->
        do_map_list(f, values, typeclass, values)

      false ->
        f.(map_type(values, typeclass), typeclass)
    end
  end

  defp do_map_list(f, [%Undetermined{}], typeclass, values) do
    new(fn type -> map_list(f, values, type) end, typeclass)
  end

  defp do_map_list(f, [%Undetermined{} | t], typeclass, values) do
    do_map_list(f, t, typeclass, values)
  end

  defp do_map_list(f, [a | _t], _typeclass, values) do
    type = Generated.type(a)
    f.(map_type(values, type), type)
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
