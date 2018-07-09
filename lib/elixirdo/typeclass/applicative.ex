defmodule Elixirdo.Typeclass.Applicative do
  use Elixirdo.Base
  use Elixirdo.Expand

  defmacro __using__(opts) do
    import_typeclass = Keyword.get(opts, :import_typeclass, false)

    quoted_import =
      case import_typeclass do
        true ->
          [quote(do: import_typeclass(Applicative.applicative()))]

        false ->
          []
      end

    quote do
      use Elixirdo.Typeclass.Functor, unquote(opts)
      alias Elixirdo.Typeclass.Applicative
      unquote_splicing(quoted_import)
    end
  end

  defclass applicative(f, f: functor) do
    def pure(a) :: f(a)

    def ap(applicative_f: f((a -> b)), applicative_a: f(a)) :: f(b) do
      lift_a2(fn fun, x -> fun.(x) end, applicative_f, applicative_a, f)
    end

    def lift_a2(ab_c: (a, b -> c), applicative_a: f(a), applicative_b: f(b)) :: f(c) do
      a_b_c = fn a -> fn b -> ab_c.(a, b) end end
      pure(a_b_c, f) |> ap(applicative_a, f) |> ap(applicative_b, f)
    end
  end

  def lift_a3(f, aa, ab, ac, type \\ :applicative) do
    nf = fn a, b -> fn c -> f.(a, b, c) end end
    ap(lift_a2(nf, aa, ab, type), ac, type)
  end
end
