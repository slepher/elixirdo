defmodule Elixirdo.Typeclass.Applicative do

  import Elixirdo.Base.Class, only: [defclass: 2]

  defclass applicative f, f: functor do
    defi pure(a) :: f(a)

    defi ap(f(a ~> b), f(a)) :: f(b)

    defi lift_a2(ab_c: a.b ~> c, applicative_a: f(a), applicative_b: f(b)) :: f(c) do
      a_b_c = fn a -> fn b -> ab_c.(a, b) end end
      applicative_f = pure(a_b_c, f)
      f.ap(f.ap(applicative_f, applicative_a), applicative_b)
    end
  end

  def lift_a3(f, aa, ab, ac, applicative) do
    nf = fn a -> fn b -> fn c -> f.(a, b, c) end end end
    ap(lift_a2(nf, aa, ab, applicative), ac, applicative)
  end

end
