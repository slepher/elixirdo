defmodule Elixirdo.Monad do

  alias Elixirdo.Applicative
  alias Elixirdo.TypeclassTrans
  alias Elixirdo.Undetermined

  def bind(ua, kub, umonad \\ :monad) do
    Undetermined.map(fn monad, ma ->
      kmb = fn a -> Undetermined.run(kub.(a), monad) end
      do_bind(ma, kmb, monad)
    end, ua, umonad)
  end

  def then(ua, ub, umonad \\ :monad) do
    Undetermined.map_pair(fn monad, ma, mb -> do_then(ma, mb, monad) end, ua, ub, umonad)
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

  defmacro monad(type, do: body) do
      [h | t] = Enum.reverse(body)
      List.foldl(t, h, fn
        (continue, {:let, _, [{:=, _, [assign, value]}]}) ->
          quote do: unquote(value) |> fn unquote(assign) -> unquote(continue) end.()
        (continue, {:<-, _, [assign, value]}) ->
          quote do
            bind(unquote(value), (fn unquote(assign) -> unquote(continue) end), unquote(type))
          end
        (continue, value) ->
          quote do
            bind(unquote(value), fn _ -> unquote(continue) end, unquote(type))
          end
        end)
  end

  defp do_bind(ma, kmb, monad) do
    TypeclassTrans.apply(:bind, [ma, kmb], monad, :monad)
  end

  defp do_then(ma, mb, monad) do
    TypeclassTrans.apply(:then, [ma, mb], monad, :monad)
  end

  defp do_return(a, monad) do
    TypeclassTrans.apply(:return, [a], monad, :monad)
  end

end
