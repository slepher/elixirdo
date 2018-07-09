defmodule Elixirdo.Instance.MonadTrans.Except do

  use Elixirdo.Base
  use Elixirdo.Typeclass.Monad.Trans, import_typeclasses: true
  use Elixirdo.Typeclass.Monad.Fail, import_monad_fail: true
  use Elixirdo.Instance.Either

  alias Elixirdo.Instance.MonadTrans.Except, as: ExceptT

  defmacro __using__(_) do
    quote do
      use Elixirdo.Instance.Either
      alias Elixirdo.Instance.MonadTrans.Except, as: ExceptT
    end
  end

  defstruct [:value]

  deftype except_t(e, m, a) :: %ExceptT{value: m(Either.either(e, a))}

  def new(m) do
    %ExceptT{value: m}
  end

  def run(%ExceptT{value: m}) do
    m
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
      new(Monad.return(Either.pure(a), m))
    end

    def ap(except_t_f, except_t_a) do
      new(
        monad m do
          either_f <- run(except_t_f)

          case either_f do
            %Left{} ->
              Monad.return(either_f, m)

            %Right{} ->
              f = Right.run(either_f)

              monad m do
                either_a <- run(except_t_a)

                case either_a do
                  %Left{} ->
                    Monad.return(either_a, m)

                  %Right{} ->
                    a = Right.run(either_a)
                    Monad.return(Right.new(f.(a)), m)
                end
              end
          end
        end
      )
    end
  end

  definstance monad(except_t(e, m), m: monad) do
    def bind(except_t_a, afb) do
      new(
        monad m do
          either_a <- run(except_t_a)

          case either_a do
            %Left{} ->
              Monad.return(either_a, m)

            %Right{} ->
              a = Right.run(either_a)
              run(afb.(a))
          end
        end
      )
    end
  end

  definstance monad_trans(except_t(e, m), m: monad) do
    def lift(monad_a) do
      ExceptT.new(Monad.lift_m(fn a -> Right.new(a) end, monad_a, m))
    end
  end

  definstance monad_fail(except_t(e, m), m: monad) do
    def fail(e) do
      new(Monad.return(Either.fail(e), m))
    end
  end

  def map(f, except_t_a) do
    new(f.(run(except_t_a)))
  end
end
