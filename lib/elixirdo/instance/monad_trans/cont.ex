defmodule Elixirdo.Instance.MonadTrans.Cont do
  alias Elixirdo.Instance.MonadTrans.Cont
  use Elixirdo.Base.Type
  use Elixirdo.Base.Instance
  use Elixirdo.Typeclass.Monad
  use Elixirdo.Typeclass.Monad.MonadTrans
  use Elixirdo.Typeclass.Monad.MonadCont

  use Elixirdo.Expand

  defstruct [:data]

  deftype(cont_t(r, m, a) :: %Cont{data: ((a -> m(r)) -> m(r))})

  def new_cont_t(inner) do
    %Cont{data: inner}
  end

  def run_cont_t(%Cont{data: inner}) do
    inner
  end

  def run(cont_t, cc) do
    run_cont_t(cont_t).(cc)
  end

  definstance functor(cont_t(r, m)) do
    def fmap(f, cont_t_a) do
      new_cont_t(fn cc ->
        run(cont_t_a, fn a -> cc.(f.(a)) end)
      end)
    end
  end

  definstance applicative(cont_t(r, m)) do
    def pure(a) do
      new_cont_t(fn k -> k.(a) end)
    end

    def ap(cont_t_f, cont_t_a) do
      new_cont_t(fn cc ->
        run(cont_t_f, fn f -> run(cont_t_a, fn a -> cc.(f.(a)) end) end)
      end)
    end
  end

  definstance monad(cont_t(r, m)) do
    def bind(cont_t_a, afb) do
      new_cont_t(fn k ->
        run(cont_t_a, fn a ->
          run(afb.(a), k)
        end)
      end)
    end
  end

  definstance monad_trans(cont_t(r, m), m: monad) do
    def lift(monad_a) do
      new_cont_t(fn cc -> Monad.bind(monad_a, cc, m) end)
    end
  end

  definstance monad_cont(cont_t(r, m)) do
    def callCC(f) do
      new_cont_t(fn cc -> run(f.(fn a -> new_cont_t(fn _ -> cc.(a) end) end), cc) end)
    end
  end
end
