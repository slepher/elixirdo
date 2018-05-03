defmodule Elixirdo.Typeclass.Functor do
  alias Elixirdo.Base.Undetermined
  alias Elixirdo.Base.Generated

  @p_typeclass :functor

  @type t :: any()

  @callback fmap((any() -> any()), t(), any()) :: t()

  @spec fmap((any() -> any()), t(), any()) :: t()
  def fmap(f, ua, ufunctor \\ @p_typeclass) do
    Undetermined.map(fn fa, functor -> do_fmap(f, fa, functor) end, ua, ufunctor)
  end

  defp do_fmap(f, fa, functor) do
    module = Generated.module(functor, @p_typeclass)
    module.fmap(f, fa, functor)
  end
end
