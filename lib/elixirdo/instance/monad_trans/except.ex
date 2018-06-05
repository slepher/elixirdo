defmodule Elixirdo.Instance.MonadTrans.Except do
  alias Elixirdo.Instance.MonadTrans.Except
  alias Elixirdo.Instance.Either

  defstruct [:data]

  use Elixirdo.Typeclass.Monad
  use Elixirdo.Base.Type
  use Elixirdo.Base.Instance
  use Elixirdo.Expand

  deftype(error_t(e, m, a) :: %Except{data: inner_error_t(e, m, a)})
  deftype(inner_error_t(e, m, a) :: Monad.m(m, Either.either(e, a)), export: false)

  def error_t(m) do
    %Except{data: m}
  end

  def run_error_t(%Except{data: inner}) do
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
      error_t(
        monad :monad do
          either_f <- run_error_t(error_t_f)
          case either_f do
            {:left, _} ->
              Monad.return(either_f)
            {:right, f} ->
              monad :monad do
                either_a <- run_error_t(error_t_a)
                case either_a do
                  {:left, _} ->
                    Monad.return(either_a)
                  {:right, a} ->
                    Monad.return({:right, f.(a)})
                end
              end
          end
        end
      )
    end
  end

  definstance monad(error_t) do
    def bind(error_t_a, afb) do
      error_t(
        monad :monad do
          either_a <- run_error_t(error_t_a)
          case either_a do
            {:left, _} ->
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
