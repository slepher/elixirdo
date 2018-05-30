defmodule Elixirdo.MaybeT do
  alias Elixirdo.MaybeT
  alias Elixirdo.Typeclass.Functor
  alias Elixirdo.Typeclass.Applicative
  alias Elixirdo.Typeclass.Monad

  import Elixirdo.Typeclass.Functor, only: [functor: 0]
  import Elixirdo.Typeclass.Applicative, only: [applicative: 0]

  use Elixirdo.Base
  use Elixirdo.Expand

  defstruct [:data]

  deftype maybe_t(_m, _a) :: %MaybeT{data: any()}

  definstance functor maybe_t(m)  do
    def fmap(f, mta) do
      map(fn ma -> Functor.fmap(fn maybe_a -> Functor.fmap(f, maybe_a) end, ma) end, mta)
    end
  end

  definstance applicative maybe_t(m) do
    def pure(a) do
      maybe_t(Applicative.pure({:just, a}))
    end

    def ap(mtf, mta) do
      maybe_t(
        Monad.bind(run_maybe_t(mtf), fn maybe_f ->
          case maybe_f do
            :nothing ->
              Monad.return(:nothing)

            {:just, f} ->
              Functor.fmap(fn maybe_a -> Functor.fmap(f, maybe_a) end, run_maybe_t(mta))
          end
        end)
      )
    end
  end

  def bind(mta, kmtb, _) do
    maybe_t(
      Monad.bind(run_maybe_t(mta), fn maybe_a ->
        case maybe_a do
          :nothing ->
            Monad.return(:nothing)

          {:just, a} ->
            run_maybe_t(kmtb.(a))
        end
      end)
    )
  end

  def map(f, mta) do
    maybe_t(f.(run_maybe_t(mta)))
  end

  def maybe_t(data) do
    %MaybeT{data: data}
  end

  def run_maybe_t(%MaybeT{data: data}) do
    data
  end
end
