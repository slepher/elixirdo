defmodule Elixirdo.Applicative do

  def pure(a, uapplicative) do
    Undetermined.new(fn applicative -> TypeclassTrans.apply(:pure, [a], applicative, __MODULE__) end, uapplicative)
  end

  def unquote(:"<*>")(uf, ua, uapplicative) do
    Undetermined.map_pair(fn applicative, af, aa -> func_do____(af, aa, applicative) end, uf, ua, uapplicative)
  end

  def lift_a2(f, ua, ub, uapplicative) do
    Undetermined.map_pair(fn applicative, aa, ab -> do_lift_a2(f, aa, ab, applicative) end, ua, ub, uapplicative)
  end

  def unquote(:"*>")(uA, uB, uApplicative) do
    Undetermined.map_pair(fn applicative, aA, aB -> TypeclassTrans.apply(:"*>", [aA, aB], applicative, __MODULE__) end, uA, uB, uApplicative)
  end

  def unquote(:"<*")(ua, ub, uapplicative) do
    Undetermined.map_pair(fn applicative, aa, ab -> TypeclassTrans.apply(:"<*", [aa, ab], applicative, __MODULE__) end, ua, ub, uapplicative)
  end

  def unquote(:"default_<*>")(aF, aA, applicative) do
    fA = fn f, a -> f.(a) end
    lift_a2(fA, aF, aA, applicative)
  end

  def default_lift_a2(f, aA, aB, applicative) do
    nF = fn a -> fn b -> f.(a, b) end end
    aF = :applicative.pure(nF, applicative)
    func_do____(func_do____(aF, aA, applicative), aB, applicative)
  end

  def unquote(:"default_*>")(aA, aB, applicative) do
    constId = fn _a -> fn b -> b end end
    do_lift_a2(constId, aA, aB, applicative)
  end

  def unquote(:"default_<*")(aa, ab, applicative) do
    const = fn a -> fn _b -> a end end
    do_lift_a2(const, aa, ab, applicative)
  end

  def ap(aF, a, applicative) do
    Kernel.apply(__MODULE__, :"<*>", [aF, a, applicative])
  end

  def unquote(:"<**>")(aA, aF, applicative) do
    Kernel.apply(__MODULE__, :"<*>", [aF, aA, applicative])
  end

  def lift_a3(f, aA, aB, aC, applicative) do
    nF = fn a -> fn b -> fn c -> f.(a, b, c) end end end
    Kernel.apply(__MODULE__, :"<*>", [lift_a2(nF, aA, aB, applicative), aC, applicative])
  end

  defp func_do____(aF, aA, applicative) do
    TypeclassTrans.apply(:"<*>", [aF, aA], applicative, __MODULE__)
  end

  defp do_lift_a2(f, aA, aB, applicative) do
    TypeclassTrans.apply(:lift_a2, [f, aA, aB], applicative, __MODULE__)
  end

end
