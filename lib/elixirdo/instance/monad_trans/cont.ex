defmodule Elixirdo.Instance.MonadTrans.Cont do
  alias Elixirdo.Instance.MonadTrans.Cont
  use Elixirdo.Base.Type
  use Elixirdo.Base.Instance
  use Elixirdo.Typeclass.Monad

  defstruct [:data]

  deftype(cont_t(r, m, a) :: %Cont{data: inner_cont_t(r, m, a)})
  deftype(inner_cont_t(r, m, a) :: ((a -> Monad.m(m, r)) -> Monad.m(m, r)), export: false)

  def cont_t(inner) do
    %Cont{data: inner}
  end

  def run_cont_t(%Cont{data: inner}) do
    inner
  end

  def run(cont_t, cc) do
    run_cont_t(cont_t).(cc)
  end

  definstance functor(cont_t) do
    def fmap(f, cont_t_a) do
      cont_t(fn cc ->
        run(cont_t_a, fn a -> cc.(f.(a)) end)
      end)
    end
  end

  definstance applicative(cont_t) do
    def pure(a) do
      cont_t(fn k -> k.(a) end)
    end

    def ap(cont_t_f, cont_t_a) do
      cont_t(fn cc ->
        run(cont_t_f, fn f -> run(cont_t_a, fn a -> cc.(f.(a)) end) end)
      end)
    end
  end

  definstance monad(cont_t) do
    def bind(cont_t_a, afb) do
      cont_t(fn k ->
        run(cont_t_a, fn a ->
          run(afb.(a), k)
        end)
      end)
    end
  end
end
