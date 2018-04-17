defmodule Elixirdo.Functor do
  alias Elixirdo.Undetermined
  alias Elixirdo.Typeclass.Generated

  @type t :: any()

  @spec fmap(t(), (any() -> any())) :: t()
  def fmap(f, functor_a) do
    fmap(f, functor_a, :functor)
  end

  @spec fmap(t(), (any() -> any()), any()) :: t()
  def fmap(f, ua, ufunctor) do
    Undetermined.map(fn functor, fa -> do_fmap(f, fa, functor) end, ua, ufunctor)
  end

  defp do_fmap(f, fa, functor) do
    module = Generated.module(functor, :functor)
    module.fmap(f, fa, %{:functor => functor})
  end
end
