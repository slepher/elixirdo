defmodule Elixirdo.Instance.MonadTrans.State do
  use Elixirdo.Base
  use Elixirdo.Typeclass.Monad
  use Elixirdo.Typeclass.Monad.MonadState
  use Elixirdo.Typeclass.Monad.MonadTrans

  alias Elixirdo.Instance.MonadTrans.State

  use Elixirdo.Expand

  defstruct [:data]

  deftype state_t(s, m, a) :: %State{data: (s -> m({a, s}))}

  def new_state_t(data) do
    %State{data: data}
  end

  def run_state_t(%State{data: inner}) do
    inner
  end

  def run(state_t_a, state) do
    run_state_t(state_t_a).(state)
  end

  def map(f, state_t_a) do
    new_state_t(fn state -> f.(run(state_t_a, state)) end)
  end

  definstance functor state_t(s, m), m: functor do
    def fmap(f, state_t_a) do
      map(
        fn functor_a ->
          Functor.fmap(fn {a, state} -> {f.(a), state} end, functor_a, m)
        end,
        state_t_a
      )
    end
  end

  definstance applicative state_t(s, m), m: monad do
    def pure(a) do
      do_state(fn s -> {a, s} end, m)
    end

    def ap(state_t_f, state_t_a) do
      new_state_t(
        fn s ->
          monad m do
            {f, ns} <- run(state_t_f, s)
            {a, nns} <- run(state_t_a, ns)
            Monad.return({f.(a), nns}, m)
          end
        end)
    end
  end

  definstance monad state_t(s, m), m: monad  do
    def bind(state_t_a, afb) do
      new_state_t(
        fn s ->
          monad m do
            {a, ns} <- run(state_t_a, s)
            run(afb.(a), ns)
          end
        end)
    end
  end

  definstance monad_trans state_t(s, m), m: monad do
    def lift(monad_a) do
      new_state_t(
        fn s ->
          Monad.lift_m(fn a -> {a, s} end, monad_a, m)
        end)
    end
  end

  definstance monad_state state_t(s, m), m: monad do
    def state(f) do
      do_state(f, m)
    end
  end

  def eval(state_t_a, state, m \\ :monad) do
    fn {a, _} -> a end |> Monad.lift_m(run(state_t_a, state), m)
  end

  def exec(state_t_a, state, m \\ :monad) do
    fn {_, s} -> s end |> Monad.lift_m(run(state_t_a, state), m)
  end

  defp do_state(f, m) do
    new_state_t(fn state ->
      Monad.return(f.(state), m)
    end)
  end
end
