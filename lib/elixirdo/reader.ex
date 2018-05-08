defmodule Elixirdo.Reader do
  use Elixirdo.Base

  deftype reader(r, a) :: (r -> a)

  definstance functor reader(r) do

    def fmap(f, r) do
      fn a ->
        f.(r.(a))
      end
    end
  end

end
