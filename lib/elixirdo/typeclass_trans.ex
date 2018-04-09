defmodule Elixirdo.TypeclassTrans do

  alias Elixirdo.Typeclass

  def apply(f, args, {t, m}, typeclass) do
    module = Typeclass.module(t, typeclass)
    Kernel.apply(module, f, args ++ [{t, m}])
  end

  def apply(f, args, m, typeclass) when is_atom(m) do
    module = Typeclass.module(m, typeclass)
    Kernel.apply(module, f, args ++ [m])
  end

end
