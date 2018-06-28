defmodule Elixirdo.Base.Lens do

  def view_all_by_type_attributes(var_type_attributes) do
    view_all_by_type_attributes(var_type_attributes, Map.new())
  end

  def view_all_by_type_attributes([], acc) do
    acc
  end

  def view_all_by_type_attributes([{var, type_attributes}|t], acc) do
    acc = view_by_type_attributes(type_attributes, var, acc)
    view_all_by_type_attributes(t, acc)
  end

  def view_by_type_attributes(type_attributes, var) do
    view_by_type_attributes(type_attributes, var, Map.new())
  end

  def view_by_type_attributes([], _var, acc) do
    acc
  end

  def view_by_type_attributes([{type_var, attributes}|t], var, acc) do
    lens = lens(attributes)
    a = view(lens, var)
    as = Map.get(acc, type_var, [])
    acc = Map.put(acc, type_var, [a|as])
    view_by_type_attributes(t, var, acc)
  end

  def lens(lens_attributes) do
    lens(lens_attributes, id_lens())
  end

  def lens([], lens) do
    lens
  end

  def lens([h|t], lens) do
    lens = compose(attr_lens(h), lens)
    lens(t, lens)
  end

  def attr_lens({:tuple, n}) do
    tuple_lens(n)
  end

  def attr_lens({:map, key}) do
    map_lens(key)
  end

  def id_lens() do
    {fn s -> s end, fn _s, b -> b end}
  end

  def tuple_lens(offset) do
    {fn s ->
       :erlang.element(offset, s)
     end,
     fn s, b ->
       :erlang.setelement(offset, s, b)
     end}
  end

  def map_lens(key) do
    {fn s ->
       Map.get(s, key)
     end,
     fn s, b ->
       Map.put(s, key, b)
     end}
  end

  def view({getter, _}, s) do
    getter.(s)
  end

  def set({_, setter}, s, b) do
    setter.(s, b)
  end

  ## getter1 : s -> a
  ## getter2 : a -> x
  ## setter1 : s -> b -> t
  ## setter2 : a -> y -> b
  def compose({getter1, setter1}, {getter2, setter2}) do
    {fn s ->
       getter2.(getter1.(s))
     end,
     fn s, y ->
       a = getter1.(s)
       b = setter2.(a, y)
       setter1.(s, b)
     end}
  end
end
