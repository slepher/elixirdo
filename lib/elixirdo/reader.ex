defmodule Elixirdo.Reader do
  use Elixirdo.Base

  import Elixirdo.Typeclass.Functor, only: [functor: 0]
  import Elixirdo.Typeclass.Applicative, only: [applicative: 0]

  deftype reader(r, a) :: (r -> a)

  definstance functor reader(r) do

    def fmap(f, r) do
      fn a ->
        f.(r.(a))
      end
    end
  end

end
