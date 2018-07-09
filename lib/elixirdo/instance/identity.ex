defmodule Elixirdo.Instance.Identity do
  use Elixirdo.Base
  use Elixirdo.Typeclass.Monad, import_typeclasses: true
  use Elixirdo.Expand

  alias Elixirdo.Instance.Identity

  deftype identity(a) :: %Identity{value: a}

  defstruct [:value]

  def new(a) do
    %Identity{value: a}
  end

  def run(%Identity{value: a}) do
    a
  end

  definstance functor(identity) do
    def fmap(f, identity_a) do
      a = run(identity_a)
      new(f.(a))
    end
  end

  definstance applicative(identity) do
    def pure(a) do
      new(a)
    end

    def ap(identity_f, identity_a) do
      f = run(identity_f)
      a = run(identity_a)
      new(f.(a))
    end
  end

  definstance monad(identity) do
    def bind(identity_a, afb) do
      a = run(identity_a)
      afb.(a)
    end
  end
end
