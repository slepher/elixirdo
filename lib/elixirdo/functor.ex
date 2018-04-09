defmodule Elixirdo.Functor do

  alias Elixirdo.Function
  alias Elixirdo.Undetermined
  alias Elixirdo.TypeclassTrans

  def fmap(f, ua, ufunctor) do
    Undetermined.map(fn functor, fa -> do_fmap(f, fa, functor) end, ua, ufunctor)
  end

  def unquote(:"<$")(ub, ua, ufunctor) do
    Undetermined.map_pair(fn functor, fb, fa -> TypeclassTrans.apply(:"<$", [fb, fa], functor, __MODULE__) end, ub, ua, ufunctor)
  end

  def unquote(:"<$>")(f, fa, functor) do
    fmap(f, fa, functor)
  end

  def unquote(:"default_<$")(b, fa, functor) do
    do_fmap(Function.const(b), fa, functor)
  end

  defp do_fmap(f, fa, functor) do
    TypeclassTrans.apply(:fmap, [f, fa], functor, __MODULE__)
  end

end
