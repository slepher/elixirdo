defmodule Elixirdo.Instance.MonadTrans.Maybe do
  alias Elixirdo.Instance.MonadTrans.Maybe, as: MaybeT

  use Elixirdo.Base
  use Elixirdo.Expand
  use Elixirdo.Typeclass.Monad, import_typeclasses: true
  use Elixirdo.Typeclass.Monad.Fail, import_typeclasses: true
  use Elixirdo.Instance.Maybe

  defstruct [:value]

  deftype maybe_t(m, a) :: %MaybeT{value: m(Maybe.maybe(a))}

  defmacro __using__(_) do
    quote do
      use Elixirdo.Instance.Maybe
      alias Elixirdo.Instance.MonadTrans.Maybe, as: MaybeT
    end
  end

  def new(m) do
    %MaybeT{value: m}
  end

  def run(%MaybeT{value: m}) do
    m
  end

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
      new(Monad.return(Maybe.return(a), m))
    end

    def ap(maybe_t_f, maybe_t_a) do
      new(
        monad m do
          maybe_f <- run(maybe_t_f)

          case maybe_f do
            %Nothing{} ->
              Monad.return(Nothing.new())

            %Just{} = just_f ->
              f = Just.run(just_f)
              Functor.fmap(fn maybe_a -> Functor.fmap(f, maybe_a) end, run(maybe_t_a), m)
          end
        end
      )
    end
  end

  definstance monad(maybe_t(m), m: monad) do
    def bind(maybe_t_a, afb) do
      new(
        monad m do
          maybe_a <- run(maybe_t_a)

          case maybe_a do
            %Nothing{} ->
              Monad.return(Nothing.new(), m)

            %Just{} = maybe_a ->
              a = Just.run(maybe_a)
              run(afb.(a))
          end
        end
      )
    end
  end

  definstance monad_fail(maybe_t(m), m: monad) do
    def fail(_) do
      Monad.return(Nothing.new(), m)
    end
  end

  def map(f, maybe_t_a) do
    new(f.(run(maybe_t_a)))
  end
end
