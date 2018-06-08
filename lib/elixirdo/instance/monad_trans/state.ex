defmodule Elixirdo.Instance.MonadTrans.State do
  use Elixirdo.Base
  use Elixirdo.Typeclass.Monad
  use Elixirdo.Typeclass.Monad.MonadState
  use Elixirdo.Typeclass.Monad.MonadTrans

  alias Elixirdo.Instance.MonadTrans.State

  use Elixirdo.Expand

  defstruct [:data]

  deftype state_t(s, m, a) :: %State{data: (s -> m({a, s}))}

  def state_t(data) do
    %State{data: data}
  end

  def run_state_t(%State{data: inner}) do
    inner
  end

  def run(state_t_a, state) do
    run_state_t(state_t_a).(state)
  end

  def map(f, state_t_a) do
    state_t(fn state -> f.(run(state_t_a, state)) end)
  end

  definstance functor(state_t(m), m: functor) do
    def fmap(f, state_t_a) do
      map(
        fn functor_a ->
          Functor.fmap(fn {a, state} -> {f.(a), state} end, functor_a)
        end,
        state_t_a
      )
    end
  end

  definstance applicative(state_t(m), m: monad) do
    def pure(a) do
      state(fn s -> {a, s} end)
    end

    def ap(state_t_f, state_t_a) do
      state_t(
        fn s ->
          monad do
            {f, ns} <- run(state_t_f, s)
            {a, nns} <- run(state_t_a, ns)
            Monad.return({f.(a), nns})
          end
        end)
    end
  end

  definstance monad state_t(m), m: monad  do
    def bind(state_t_a, afb) do
      state_t(
        fn s ->
          monad do
            {a, ns} <- run(state_t_a, s)
            run(afb.(a), ns)
          end
        end)
    end
  end

  definstance monad_trans state_t(m), m: monad do
    def lift(monad_a) do
      state_t(
        fn s ->
          Monad.lift_m(fn a -> {a, s} end, monad_a)
        end)
    end
  end

  definstance monad_state(state_t) do
    def state(f) do
      state_t(fn state ->
        Monad.return(f.(state))
      end)
    end
  end

  def eval(state_t_a, state) do
    fn {a, _} -> a end |> Monad.lift_m(run(state_t_a, state))
  end

  def exec(state_t_a, state) do
    fn {_, s} -> s end |> Monad.lift_m(run(state_t_a, state))
  end
end
