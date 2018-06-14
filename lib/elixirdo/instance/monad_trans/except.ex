defmodule Elixirdo.Instance.MonadTrans.Except do
  alias Elixirdo.Instance.MonadTrans.Except
  alias Elixirdo.Instance.Either

  defstruct [:data]

  use Elixirdo.Typeclass.Monad
  use Elixirdo.Base.Type
  use Elixirdo.Base.Instance
  use Elixirdo.Expand

  deftype except_t(e, m, a) :: %Except{data: m(Either.either(e, a))}

  def new_except_t(m) do
    %Except{data: m}
  end

  def run_except_t(%Except{data: inner}) do
    inner
  end

  definstance functor(except_t(e, m), m: functor) do
    def fmap(f, except_t_a) do
      map(
        fn fa ->
          Functor.fmap(fn a -> Either.fmap(f, a) end, fa, m)
        end,
        except_t_a
      )
    end
  end

  definstance applicative(except_t(e, m), m: monad) do
    def pure(a) do
      new_except_t(Monad.return(Either.pure(a), m))
    end

    def ap(except_t_f, except_t_a) do
      new_except_t(
        monad m do
          either_f <- run_except_t(except_t_f)

          case either_f do
            {:left, _} ->
              Monad.return(either_f, m)

            {:right, f} ->
              monad m do
                either_a <- run_except_t(except_t_a)

                case either_a do
                  {:left, _} -> Monad.return(either_a, m)
                  {:right, a} -> Monad.return({:right, f.(a)}, m)
                end
              end
          end
        end
      )
    end
  end

  definstance monad(except_t(e, m), m: monad) do
    def bind(except_t_a, afb) do
      new_except_t(
        monad m do
          either_a <- run_except_t(except_t_a)

          case either_a do
            {:left, _} ->
              Monad.return(either_a, m)

            {:right, a} ->
              run_except_t(afb.(a))
          end
        end
      )
    end
  end

  def map(f, except_t_a) do
    new_except_t(f.(run_except_t(except_t_a)))
  end
end
