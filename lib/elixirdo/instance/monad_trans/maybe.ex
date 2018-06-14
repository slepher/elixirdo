defmodule Elixirdo.Instance.MonadTrans.Maybe do
  alias Elixirdo.Instance.MonadTrans.Maybe, as: MaybeT
  alias Elixirdo.Instance.Maybe

  use Elixirdo.Base
  use Elixirdo.Expand
  use Elixirdo.Typeclass.Monad

  defstruct [:data]

  deftype maybe_t(m, a) :: %MaybeT{data: m(Maybe.maybe(a))}

  definstance functor(maybe_t(m), m: functor) do
    def fmap(f, mta) do
      map(
        fn ma -> Functor.fmap(fn maybe_a -> Functor.fmap(f, maybe_a, :maybe) end, ma, m) end,
        mta
      )
    end
  end

  definstance applicative(maybe_t(m), m: monad) do
    def pure(a) do
      new_maybe_t(Monad.return({:just, a}, m))
    end

    def ap(mtf, mta) do
      new_maybe_t(
        Monad.bind(
          run_maybe_t(mtf),
          fn maybe_f ->
            case maybe_f do
              :nothing ->
                Monad.return(:nothing)

              {:just, f} ->
                Functor.fmap(fn maybe_a -> Functor.fmap(f, maybe_a) end, run_maybe_t(mta), m)
            end
          end,
          m
        )
      )
    end
  end

  definstance monad(maybe_t(m), m: monad) do
    def bind(mta, kmtb) do
      new_maybe_t(
        Monad.bind(
          run_maybe_t(mta),
          fn maybe_a ->
            case maybe_a do
              :nothing ->
                Monad.return(:nothing, m)

              {:just, a} ->
                run_maybe_t(kmtb.(a))
            end
          end,
          m
        )
      )
    end
  end

  def map(f, mta) do
    new_maybe_t(f.(run_maybe_t(mta)))
  end

  def new_maybe_t(data) do
    %MaybeT{data: data}
  end

  def run_maybe_t(%MaybeT{data: data}) do
    data
  end
end
