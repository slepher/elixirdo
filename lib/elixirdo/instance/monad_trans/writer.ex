defmodule Elixirdo.Instance.MonadTrans.Writer do
  alias Elixirdo.Instance.MonadTrans.Writer, as: WriterT

  use Elixirdo.Base
  use Elixirdo.Typeclass.Monad
  use Elixirdo.Typeclass.Monad.MonadWriter
  use Elixirdo.Typeclass.Monad.MonadTrans
  use Elixirdo.Typeclass.Monoid

  defstruct [:data]

  deftype writer_t(w, m, a) :: %WriterT{data: m({a, w()})}

  def new(data) do
    %WriterT{data: data}
  end

  def run(%WriterT{data: data}) do
    data
  end

  definstance functor(writer_t(_w, m), m: functor, _w: monoid) do
    def fmap(f, writer_t_a) do
      map(
        fn functor_a ->
          Functor.fmap(fn {a, w} -> {f.(a), w} end, functor_a, m)
        end,
        writer_t_a
      )
    end
  end

  definstance applicative(writer_t(w, m), m: applicative, w: monoid) do
    def pure(a) do
      new(Applicative.pure({a, Monoid.mempty(w)}, m))
    end

    def ap(writer_t_f, writer_t_a) do
      faw = fn {f, w1}, {a, w2} ->
        {f.(a), Monoid.mappend(w1, w2, w)}
      end

      applicative_fw = run(writer_t_f)
      applicative_aw = run(writer_t_a)
      new(Applicative.lift_a2(faw, applicative_fw, applicative_aw, m))
    end
  end

  definstance monad(writer_t(w, m), m: monad, w: monoid) do
    def bind(writer_t_a, afb) do
      new(
        monad m do
          {a, w1} <- run(writer_t_a)
          {b, w2} <- run(afb.(a))
          Monad.return(b, Monoid.mappend(w1, w2, w))
        end
      )
    end
  end

  definstance monad_trans(writer_t(w, m), m: monad, w: monoid) do
    def lift(monad_a) do
      new(Monad.lift_m(fn a -> {a, Monoid.mempty(w)} end, monad_a, m))
    end
  end

  definstance monad_writer(writer_t(_w, m), m: monad, _w: monoid) do
    def tell(ws) do
      new(Monad.return({:ok, ws}, m))
    end

    def writer({a, ws}) do
      new(Monad.return({a, ws}, m))
    end

    def listen(writer_t_a) do
      map(
        fn monad_a ->
          Monad.lift_m(fn {a, ws} -> {{a, ws}, ws} end, monad_a, m)
        end,
        writer_t_a
      )
    end

    def pass(writer_t_af) do
      map(
        fn monad_af ->
          Monad.lift_m(fn {{a, f}, ws} -> {a, f.(ws)} end, monad_af, m)
        end,
        writer_t_af
      )
    end
  end

  def map(f, writer_t_a) do
    new(f.(run(writer_t_a)))
  end
end
