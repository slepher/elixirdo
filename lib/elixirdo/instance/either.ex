defmodule Elixirdo.Instance.Either do
  use Elixirdo.Base
  use Elixirdo.Expand

  import Elixirdo.Typeclass.Functor, only: [functor: 0]
  import Elixirdo.Typeclass.Applicative, only: [applicative: 0]
  import Elixirdo.Typeclass.Monad, only: [monad: 0]

  deftype either(e, a) :: {:left, a} | {:right, e}

  def either(fac, fbc) do
    fn eab ->
      case eab do
        {:left, a} ->
          fac.(a)
        {:right, b} ->
          fbc.(b)
      end
    end
  end

  definstance functor either do
    def fmap(_f, {:left, e}) do
      {:left, e}
    end

    def fmap(f, {:right, a}) do
      {:right, f.(a)}
    end
  end

  definstance applicative either do
    def pure(a) do
      {:right, a}
    end

    def ap({:right, f}, {:right, a}) do
      {:right, f.(a)}
    end

    def ap({:left, e}, _) do
      {:left, e}
    end

    def ap(_, {:left, e}) do
      {:left, e}
    end
  end

  definstance monad either do
    def bind({:left, e}, _afb) do
      {:left, e}
    end

    def bind({:right, a}, afb) do
      case afb.(a) do
        {:right, b} ->
          {:right, b}
        {:left, e} ->
          {:left, e}
      end
    end
  end
end
