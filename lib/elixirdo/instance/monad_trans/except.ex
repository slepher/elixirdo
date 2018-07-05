defmodule Elixirdo.Instance.MonadTrans.Except do
  alias Elixirdo.Instance.MonadTrans.Except, as: ExceptT
  use Elixirdo.Instance.Either

  defstruct [:value]

  use Elixirdo.Typeclass.Monad
  use Elixirdo.Base.Type
  use Elixirdo.Base.Instance
  use Elixirdo.Expand

  deftype except_t(e, m, a) :: %ExceptT{value: m(Either.either(e, a))}

  defmacro __using__(_) do
    quote do
      use Elixirdo.Instance.Either
      alias Elixirdo.Instance.MonadTrans.Except, as: ExceptT
    end
  end

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

  def map(f, except_t_a) do
    new(f.(run(except_t_a)))
  end
end
