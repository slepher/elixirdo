defmodule Elixirdo.Base.Utils.Lens do
  alias Elixirdo.Base.Utils

  def view_all_by_type_attributes(types_attributes, vars) do
    view_all_by_type_attributes(types_attributes, vars, Map.new())
  end

  def view_all_by_type_attributes([], [], acc) do
    acc
  end

  def view_all_by_type_attributes([type_attributes | t], [var | var_t], acc) do
    acc = view_by_type_attributes(type_attributes, var, acc)
    view_all_by_type_attributes(t, var_t, acc)
  end

  def view_by_type_attributes(type_attributes, var) do
    view_by_type_attributes(type_attributes, var, Map.new())
  end

  def view_by_type_attributes([], _var, acc) do
    acc
  end

  def view_by_type_attributes([{type_var, attributes} | t], var, acc) do
    lens = attrs_lens(attributes)
    a = view(lens, var)
    as = Map.get(acc, type_var, [])
    acc = Map.put(acc, type_var, [a | as])
    view_by_type_attributes(t, var, acc)
  end

  def lens_of_type(type) do
    lens_of_type(type, [], [])
  end

  def lens_of_type(%Utils.Type{typeclasses: []}, _attributes, acc) do
    acc
  end

  def lens_of_type(%Utils.Type{type: type}, attributes, acc) when is_atom(type) do
    [{type, attributes} | acc]
  end

  def lens_of_type(%Utils.Type{type: %Utils.Type.Function{} = type}, attributes, acc) do
    [{type, attributes} | acc]
  end

  def lens_of_type(%Utils.Type{type: %Utils.Type.Tuple{elements: element_types}}, attributes, acc) do
    List.foldl(
      Enum.to_list(1..length(element_types)),
      acc,
      fn n, acc1 ->
        attributes = [{:tuple, n} | attributes]
        element_type = :lists.nth(n, element_types)
        lens_of_type(element_type, attributes, acc1)
      end
    )
  end

  def lens_of_type(%Utils.Type{type: %Utils.Type.Map{map_pairs: map_types}}, attributes, acc) do
    List.foldl(
      map_types,
      acc,
      fn {key, value_type}, acc1 ->
        attributes = [{:map, key} | attributes]
        lens_of_type(value_type, attributes, acc1)
      end
    )
  end

  def attrs_lens(attrs) do
    :lists.foldl(
      fn attr, acc ->
        compose(acc, attr_lens(attr))
      end, id_lens(), attrs)
  end

  def attr_lens({:tuple, n}) do
    tuple_lens(n)
  end

  def attr_lens({:list, n}) do
    list_lens(n)
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

  def list_lens(offset) do
    {fn s ->
      Enum.at(s, offset - 1)
     end,
     fn s, b ->
      List.replace_at(s, offset - 1, b)
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

  def rcomposes_attrs(attrs_lenses, rattrs_lenses, init) do
    lenses = attrs_lenses |> Enum.map(&attrs_lens/1)
    rlenses = rattrs_lenses |> Enum.map(&attrs_lens/1)
    rcomposes(lenses, rlenses, init)
  end

  def rcomposes(lenses, rlenses, init) do
    {
      fn s ->
        as =
          lenses
          |> Enum.map(fn lens ->
            view(lens, s)
          end)

        :lists.foldl(
          fn n, acc ->
            an = :lists.nth(n, as)
            rlens = :lists.nth(n, rlenses)
            set(rlens, acc, an)
          end,
          init,
          :lists.seq(1, length(lenses))
        )
      end,
      fn s, b ->
        bs =
          rlenses
          |> Enum.map(fn lens ->
            view(lens, b)
          end)

        :lists.foldl(
          fn n, acc ->
            bn = :lists.nth(n, bs)
            lens = :lists.nth(n, lenses)
            set(lens, acc, bn)
          end,
          s,
          :lists.seq(1, length(lenses))
        )
      end
    }
  end

  def rcompose({getter, setter}, {rgetter, rsetter}, init) do
    {
      fn s ->
        a = getter.(s)
        rsetter.(init, a)
      end,
      fn s, final ->
        b = rgetter.(final)
        setter.(s, b)
      end
    }
  end
end
