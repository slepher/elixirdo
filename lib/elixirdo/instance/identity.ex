defmodule Elixirdo.Instance.Identity do
  use Elixirdo.Base.Type
  use Elixirdo.Base.Instance
  use Elixirdo.Typeclass.Monad
  use Elixirdo.Expand

  alias Elixirdo.Instance.Identity

  defstruct [:value]

  deftype identity(a) :: %Identity{value: a}

  def new_identity(a) do
    %Identity{value: a}
  end

  def run_identity(%Identity{value: a}) do
    a
  end

  definstance functor(identity) do
    def fmap(f, identity_a) do
      a = run_identity(identity_a)
      new_identity(f.(a))
    end
  end

  definstance applicative(identity) do
    def pure(a) do
      new_identity(a)
    end

    def ap(identity_f, identity_a) do
      f = run_identity(identity_f)
      a = run_identity(identity_a)
      new_identity(f.(a))
    end
  end

  definstance monad(identity) do
    def bind(identity_a, afb) do
      a = run_identity(identity_a)
      afb.(a)
    end
  end
end
