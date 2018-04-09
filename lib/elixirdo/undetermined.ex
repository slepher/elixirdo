  
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

  def map(f, %Elixirdo.Undetermined{inner_function: uf}, typeclass) do
    case(Typeclass.is_typeclass(typeclass)) do
      true ->
        new(fn module -> f.(module, uf.(module)) end, typeclass)
      false ->
        f.(typeclass, uf.(typeclass))
    end
  end

  def map(f, m, typeclass) do
    case(Typeclass.is_typeclass(typeclass)) do
      true ->
        case(Typeclass.type(m)) do
          :undefined ->
            new(fn type -> f.(type, m) end, typeclass)
          type ->
            f.(type, m)
        end
      false ->
        f.(typeclass, m)
    end
  end


  def map_pair(f, %Elixirdo.Undetermined{} = ua, ub, typeclass) do
    Undetermined.map(fn module, b ->
      a = run(ua, module)
      f.(module, a, b)
    end, ub, typeclass)
  end

  def map_pair(f, ua, ub, typeclass) do
    Undetermined.map(fn module, a ->
      b = run(ub, module)
      f.(module, a, b)
    end, ua, typeclass)
  end

end
