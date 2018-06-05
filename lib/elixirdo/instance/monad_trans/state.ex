defmodule Elixirdo.Instance.MonadTrans.State do
  use Elixirdo.Base
  use Elixirdo.Typeclass.Monad
  use Elixirdo.Typeclass.Monad.MonadState
  alias Elixirdo.Instance.MonadTrans.State

  defstruct [:data]

  deftype(state_t(s, m, a) :: %State{data: inner_state_t(s, m, a)})

  deftype(inner_state_t(s, m, a) :: (s -> Monad.m(m, {a, s})), export: false)

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

  definstance functor(state_t) do
    def fmap(f, state_t_a) do
      map(
        fn functor_a ->
          Functor.fmap(fn {a, state} -> {f.(a), state} end, functor_a)
        end,
        state_t_a
      )
    end
  end

  definstance applicative(state_t) do
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

  definstance monad state_t do
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
