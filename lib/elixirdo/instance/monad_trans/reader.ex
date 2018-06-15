defmodule Monad.Instance.MonadTrans.Reader do

  alias Monad.Instance.MonadTrans.Reader

  use Elixirdo.Base
  use Elixirdo.Typeclass.Monad
  use Elixirdo.Typeclass.Monad.MonadTrans
  use Elixirdo.Typeclass.Monad.MonadReader

  defstruct [:data]

  deftype reader_t(r, m, a) :: %Reader{data: (r -> m(a))}

  def new_reader_t(data) do
    %Reader{data: data}
  end

  def run_reader_t(%Reader{data: data}) do
    data
  end

  def run(reader_t_a, r) do
    (run_reader_t(reader_t_a)).(r)
  end

  definstance functor reader_t(r, m), m: functor do
    def fmap(f, reader_t_a) do
      new_reader_t(
        fn r ->
          functor_a = run(reader_t_a, r)
          Functor.fmap(f, functor_a, m)
        end
      )
    end
  end

  definstance applicative reader_t(r, m), m: applicative do
    def pure(a) do
      new_reader_t(
        fn _ ->
          Applicative.pure(a, m)
        end
      )
    end

    def ap(reader_t_f, reader_t_a) do
      new_reader_t(
        fn r ->
          applicative_f = run(reader_t_f, r)
          applicative_a = run(reader_t_a, r)
          Applicative.ap(applicative_f, applicative_a, m)
        end
      )
    end
  end

  definstance monad reader_t(r, m), m: monad do
    def bind(reader_t_a, afb) do
      new_reader_t(
        fn r ->
          monad m do
            a <- run(reader_t_a, r)
            run(afb.(a), r)
          end
        end
      )
    end
  end

  definstance monad_trans reader_t(r, m) do
    def lift(monad_a) do
      new_reader_t(
        fn _ ->
          monad_a
        end
      )
    end
  end

  definstance monad_reader reader_t(r, m), m: monad do
    def local(f, reader_a) do
      with_reader(f, reader_a, m)
    end

    def ask() do
      new_reader_t(fn r -> Monad.return(r, m) end)
    end

    def reader(f) do
      new_reader_t(fn r -> Monad.return(f.(r), m) end)
    end
  end

  def with_reader(f, reader_a) do
    new_reader_t(fn r -> run(reader_a, f.(r)) end)
  end

  def with_reader(f, reader_a, _m) do
    with_reader(f, reader_a)
  end
end
