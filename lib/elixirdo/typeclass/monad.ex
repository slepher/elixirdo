defmodule Elixirdo.Typeclass.Monad do

  alias Elixirdo.Applicative
  alias Elixirdo.Base.Undetermined
  alias Elixirdo.Base.Generated

  def bind(ua, kub, umonad \\ :monad) do
    Undetermined.map(fn ma, monad ->
      kmb = fn a -> Undetermined.run(kub.(a), monad) end
      do_bind(ma, kmb, monad)
    end, ua, umonad)
  end

  def then(ua, ub, umonad \\ :monad) do
    Undetermined.map_list(fn [ma, mb], monad -> do_then(ma, mb, monad) end, [ua, ub], umonad)
  end

  def return(a, umonad \\ :monad) do
    Undetermined.new(fn monad -> do_return(a, monad) end, umonad)
  end

  def default_then(ma, mb, monad) do
    bind(ma, fn _ -> mb end, monad)
  end

  def default_return(a, monad) do
    Applicative.pure(a, monad)
  end

  def join(mma, monad \\ :monad) do
    bind(mma, fn ma -> ma end, monad)
  end

  def lift_m(f, ma, monad \\ :monad) do
    bind(ma, fn a -> return(f.(a)) end, monad)
  end

  defp do_bind(ma, k_mb, monad) do
    module = Generated.module(monad, :monad)
    module.bind(ma, k_mb, monad)
  end

  defp do_then(ma, mb, monad) do
    module = Generated.module(monad, :monad)
    module.then(ma, mb, monad)
  end

  defp do_return(a, monad) do
    module = Generated.module(monad, :monad)
    module.return(a, monad)
  end

end
