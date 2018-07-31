defmodule Elixirdo.Typeclass.Monoid do
  use Elixirdo.Base
  use Elixirdo.Expand
  use Elixirdo.Typeclass.Semigroup

  defmacro __using__(opts) do
    quote do
      use Elixirdo.Typeclass.Semigroup, unquote(opts)
      alias Elixirdo.Typeclass.Monoid
      unquote_splicing(__using_import__(opts))
    end
  end

  defclass monoid(m, m: semigroup) do
    def mempty() :: m

    def mappend(ma: m, mb: m) :: m do
      Semigroup.sappend(ma, mb, m)
    end

    law left_identity(x: m(a)) :: m(a) do
      m |> mappend(mempty()) === m
    end

    law right_identity(x: m(a)) :: m(a) do
      mempty() |> mappend(m) === m
    end

    law composition(x: m(a), y: m(a), z: m(a)) :: m(a) do
      mappned(x, y) |> mappend(z) === x |> mappend(y, z)
    end
  end
end
