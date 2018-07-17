defmodule Elixirdo.Typeclass.Monoid do
  use Elixirdo.Base
  use Elixirdo.Expand

  defmacro __using__(opts) do
    quote do
      alias Elixirdo.Typeclass.Monoid
      unquote_splicing(__using_import__(opts))
    end
  end

  defclass monoid(m) do
    def mempty() :: m

    def mappend(m, m) :: m

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
