defmodule Elixirdo.Base.Utils do

  def kvs_to_map(kvs) do
    :lists.foldl(
      fn {k, v}, acc ->
        vs = Map.get(acc, k, [])
        Map.put(acc, k, [v|vs])
      end, Map.new(), kvs)
  end

  def filter_by_offsets(offsets, xs) do
    offsets |> Enum.map(fn n -> :lists.nth(n ,xs) end)
  end

  def var_fn(module, gen_name) when is_function(gen_name) do
    fn pos ->
      name = gen_name.(pos)
      Macro.var(String.to_atom(name <> Integer.to_string(pos)), module)
    end
  end

  def var_fn(module, name) do
    fn pos -> Macro.var(String.to_atom(name <> Integer.to_string(pos)), module) end
  end
end
