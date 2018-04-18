defmodule Elixirdo.Typeclass.Applicative do

  alias Elixirdo.Base.Undetermined
  alias Elixirdo.Base.Generated

  def pure(a, uapplicative \\ :applicative) do
    Undetermined.new(fn applicative -> do_pure(a, applicative) end, uapplicative)
  end

  def lift_a2(f, ua, ub, uapplicative \\ :applicative) do
    Undetermined.map_list(fn [aa, ab], applicative -> do_lift_a2(f, aa, ab, applicative) end, [ua, ub], uapplicative)
  end

  def ap(uf, ua, uapplicative \\ :applicative) do
    Undetermined.map_list(fn [af, aa], applicative -> do_ap(af, aa, applicative) end, [uf, ua], uapplicative)
  end

  def default_lift_a2(f, aa, ab, applicative) do
    nf = fn a -> fn b -> f.(a, b) end end
    af = pure(nf, applicative)
    do_ap(do_ap(af, aa, applicative), ab, applicative)
  end

  def lift_a3(f, aa, ab, ac, applicative) do
    nf = fn a -> fn b -> fn c -> f.(a, b, c) end end end
    ap(lift_a2(nf, aa, ab, applicative), ac, applicative)
  end

  defp do_pure(a, applicative) do
    module = Generated.module(applicative, :applicative)
    module.pure(a, applicative)
  end

  defp do_ap(af, aa, applicative) do
    module = Generated.module(applicative, :applicative)
    module.ap(af, aa, applicative)
  end

  defp do_lift_a2(f, aa, ab, applicative) do
    module = Generated.module(applicative, :applicative)
    module.lift_a2(f, aa, ab, applicative)
  end

end
