defmodule Elixirdo.Typeclass.Lens do

  def tuple_getter(tuple, offset) do
    fn ->
      :erlang.element(offset, tuple)
    end
  end

  def tuple_setter(tuple, offset) do
    fn value ->
      :erlang.setelement(offset, tuple, value)
    end
  end

  def map_getter(map, key) do
    fn ->
      Map.get(map, key)
    end
  end

  def map_setter(map, key) do
    fn value ->
      Map.put(map, key, value)
    end
  end
end
