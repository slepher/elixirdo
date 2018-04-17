defmodule Elixirdo.Profunctor do
  alias Elixirdo.Undetermined
  alias Elixirdo.Typeclass.Generated

  def dimap(ab, cd, uprofunctor) do
    fn ubc ->
      Undetermined.map(
        fn profunctor, profunctor_bc ->
          (do_dimap(ab, cd, profunctor)).(profunctor_bc)
        end, ubc, uprofunctor)
    end
  end

  def do_dimap(ab, cd, profunctor) do
    module = Generated.module(profunctor, :profunctor)
    module.dimap(ab, cd, profunctor)
  end
end
