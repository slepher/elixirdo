defmodule Elixirdo.Instance.Identity do
  use Elixirdo.Base.Type
  use Elixirdo.Base.Instance

  use Elixirdo.Typeclass.Monad

  deftype(identity(a) :: {:identity, a})

  definstance functor identity(a) do
    def fmap(f, {:identity, a}) do
      {:identity, f.(a)}
    end
  end

  definstance applicative identity(a) do
    def pure(a) do
      {:identity, a}
    end

    def ap({:identity, f}, {:identity, a}) do
      {:identity, f.(a)}
    end
  end

  definstance monad identity(a) do
    def bind({:identity, a}, afb) do
      afb.(a)
    end
  end
end
