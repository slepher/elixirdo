defmodule Elixirdo.Undetermined do
  alias Elixirdo.Undetermined
  alias Elixirdo.Typeclass

  defstruct [:typeclass, :inner_function]

  def new(f, typeclass) do
    case(Typeclass.is_typeclass(typeclass)) do
      true ->
        %Undetermined{typeclass: typeclass, inner_function: f}
      false ->
        f.(typeclass)
    end
  end

  def type(ua, typeclass) do
    map0(fn type, _ma -> type end, ua, typeclass)
  end

  def run(ua, typeclass) do
    map0(fn _type, ma -> ma end, ua, typeclass)
  end

  def map0(f, %Elixirdo.Undetermined{inner_function: uf} = ua, typeclass) do
    case(Typeclass.is_typeclass(typeclass)) do
      true ->
        f.(typeclass, ua)

      false ->
        f.(typeclass, uf.(typeclass))
    end
  end

  def map0(f, a, typeclass) do
    map(f, a, typeclass)
  end

  def map(f, value, typeclass) do
    map(fn type, [new_value] ->
      f.(type, new_value)
    end, value, typeclass)
  end

  def map_list(f, values, typeclass) do
    case Typeclass.is_typeclass(typeclass) do
      true ->
        do_map(f, values, typeclass, values)
      false ->
        f.(typeclass, map_type(typeclass, values))
      end
  end

  def do_map(f, [%Elixirdo.Undetermined{}], typeclass, values) do
    new(
      fn type ->
        map(f, values, type)
      end,
      typeclass
    )
  end

  def do_map(f, [%Elixirdo.Undetermined{} | t], typeclass, values) do
    do_map(f, t, typeclass, values)
  end

  def do_map(f, [a | _t], _typeclass, values) do
    type = Typeclass.type(a)
    f.(type, map_type(type, values))
  end

  def map_type(type, values) do
    Enum.map(values, fn value -> run(value, type) end)
  end

  def map_pair(f, %Elixirdo.Undetermined{} = ua, ub, typeclass) do
    Undetermined.map(
      fn module, b ->
        a = run(ua, module)
        f.(module, a, b)
      end,
      ub,
      typeclass
    )
  end

  def map_pair(f, ua, ub, typeclass) do
    Undetermined.map(
      fn module, a ->
        b = run(ub, module)
        f.(module, a, b)
      end,
      ua,
      typeclass
    )
  end
end
