defmodule Elixirdo.Reader do
  use Elixirdo.Base
  use Elixirdo.Expand

  import Elixirdo.Typeclass.Functor, only: [functor: 0]
  import Elixirdo.Typeclass.Applicative, only: [applicative: 0]

  definstance functor reader(r) do
    def fmap(f, r) do
      fn a ->
        f.(r.(a))
      end
    end
  end

  definstance applicative reader(r) do
    def pure(a) do
      fn _ -> a end
    end

    def ap(reader_f, reader_a) do
      fn r ->
        f = reader_f.(r)
        a = reader_a.(r)
        f.(a)
      end
    end
  end
end
