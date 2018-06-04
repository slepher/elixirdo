defmodule Elixirdo.Instance.MonadTrans.ErrorT do
  alias Elixirdo.Instance.MonadTrans.ErrorT
  alias Elixirdo.Instance.Either

  defstruct [:data]

  use Elixirdo.Typeclass.Monad
  use Elixirdo.Base.Type
  use Elixirdo.Base.Instance
  use Elixirdo.Expand

  deftype(error_t(e, m, a) :: %ErrorT{data: inner_error_t(e, m, a)})
  deftype(inner_error_t(e, m, a) :: Monad.m(m, Either.either(e, a)))

  def error_t(m) do
    %ErrorT{data: m}
  end

  def run_error_t(%ErrorT{data: inner}) do
    inner
  end

  definstance functor(error_t) do
    def fmap(f, error_t_a) do
      map(
        fn fa ->
          Functor.fmap(fn a -> Either.fmap(f, a) end, fa)
        end,
        error_t_a
      )
    end
  end

  definstance applicative(error_t) do
    def pure(a) do
      error_t(Applicative.pure(Either.pure(a)))
    end

    def ap(error_t_f, error_t_a) do
      monad :monad do
        either_f <- run_error_t(error_t_f)
        monad :either do
          f <- either_f
          fn a -> Either.fmap(f, a) end |> Either.fmap(run_error_t(error_t_a))
        end
      end
    end
  end

  definstance monad(error_t) do
    def bind(error_t_a, afb) do
      error_t(
        monad :monad do
          either_a <- run_error_t(error_t_a)
          case either_a do
            {:left, _e} ->
              Monad.return(either_a)

            {:right, a} ->
              run_error_t(afb.(a))
          end
        end
      )
    end
  end

  def map(f, error_t_a) do
    error_t(f.(run_error_t(error_t_a)))
  end
end
