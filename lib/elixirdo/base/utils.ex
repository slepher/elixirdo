defmodule Elixirdo.Base.Utils do

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
