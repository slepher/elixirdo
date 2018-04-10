defmodule Elixirdo.Functor do

  alias Elixirdo.Undetermined
  alias Elixirdo.TypeclassTrans

  def fmap(f, ua, ufunctor \\ :functor) do
    Undetermined.map(fn functor, fa -> do_fmap(f, fa, functor) end, ua, ufunctor)
  end

  defp do_fmap(f, fa, functor) do
    TypeclassTrans.apply(:fmap, [f, fa], functor, :functor)
  end

end
