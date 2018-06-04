defmodule Elixirdo.Instance.MonadTrans.Maybe do

  alias Elixirdo.Instance.MonadTrans.Maybe

  use Elixirdo.Base
  use Elixirdo.Expand
  use Elixirdo.Typeclass.Monad

  defstruct [:data]

  deftype(maybe_t(_m, _a) :: %Maybe{data: any()})

  definstance functor(maybe_t(m)) do
    def fmap(f, mta) do
      map(fn ma -> Functor.fmap(fn maybe_a -> Functor.fmap(f, maybe_a) end, ma) end, mta)
    end
  end

  definstance applicative(maybe_t(m)) do
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

  definstance monad(maybe_t(a)) do
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
  end

  def map(f, mta) do
    maybe_t(f.(run_maybe_t(mta)))
  end

  def maybe_t(data) do
    %Maybe{data: data}
  end

  def run_maybe_t(%Maybe{data: data}) do
    data
  end
end
