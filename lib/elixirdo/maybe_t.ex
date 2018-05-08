defmodule Elixirdo.MaybeT do
  alias Elixirdo.Typeclass.Functor
  alias Elixirdo.Typeclass.Monad

  use Elixirdo.Base

  defstruct [:data]

  deftype maybe_t(m, a) :: %MaybeT{data: m(maybe(a))}

  definstance functor maybe_t(m) do
    def fmap(f, mta, m) do
      map(fn ma -> Functor.fmap(fn maybe_a -> Functor.fmap(f, maybe_a) end, ma) end, mta)
    end
  end

  def ap(mtf, mta) do
    maybe_t(
      Monad.bind(run_maybe_t(mtf),
      fn maybe_f ->
        case maybe_f do
          :nothing ->
              Monad.return(:nothing)
          {:just, f} ->
              Functor.fmap(fn maybe_a -> Functor.fmap(f, maybe_a) end, run_maybe_t(mta))
          end
      end))
  end

  def bind(mta, kmtb, _) do
    maybe_t(
      Monad.bind(run_maybe_t(mta),
      fn maybe_a ->
        case maybe_a do
          :nothing ->
            Monad.return(:nothing)
          {:just, a} ->
            run_maybe_t(kmtb.(a))
        end
      end))
  end

  def map(f, mta) do
    maybe_t(f.(run_maybe_t(mta)))
  end

  def maybe_t(data) do
    %Elixirdo.MaybeT{data: data}
  end

  def run_maybe_t(%Elixirdo.MaybeT{data: data}) do
    data
  end
end
