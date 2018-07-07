defmodule Elixirdo.Instance.MonadTrans.Cont do
  alias Elixirdo.Instance.MonadTrans.Cont, as: ContT
  use Elixirdo.Base.Type
  use Elixirdo.Base.Instance
  use Elixirdo.Typeclass.Monad
  use Elixirdo.Typeclass.Monad.MonadTrans
  use Elixirdo.Typeclass.Monad.MonadCont

  use Elixirdo.Expand

  defstruct [:data]

  deftype(cont_t(r, m, a) :: %ContT{data: ((a -> m(r)) -> m(r))})

  def new(inner) do
    %ContT{data: inner}
  end

  def run(%ContT{data: inner}) do
    inner
  end

  def run(cont_t, cc) do
    run(cont_t).(cc)
  end

  definstance functor(cont_t(r, m)) do
    def fmap(f, cont_t_a) do
      new(fn cc ->
        run(cont_t_a, fn a -> cc.(f.(a)) end)
      end)
    end
  end

  definstance applicative(cont_t(r, m)) do
    def pure(a) do
      new(fn k -> k.(a) end)
    end

    def ap(cont_t_f, cont_t_a) do
      new(fn cc ->
        run(cont_t_f, fn f -> run(cont_t_a, fn a -> cc.(f.(a)) end) end)
      end)
    end
  end

  definstance monad(cont_t(r, m)) do
    def bind(cont_t_a, afb) do
      new(fn k ->
        run(cont_t_a, fn a ->
          run(afb.(a), k)
        end)
      end)
    end
  end

  definstance monad_trans(cont_t(r, m), m: monad) do
    def lift(monad_a) do
      new(fn cc -> Monad.bind(monad_a, cc, m) end)
    end
  end

  definstance monad_cont(cont_t(r, m)) do
    def callCC(f) do
      new(fn cc -> run(f.(fn a -> new(fn _ -> cc.(a) end) end), cc) end)
    end
  end
end
