defmodule Elixirdo.Prism do
  alias Elixirdo.Typeclass.Functor
  alias Elixirdo.Typeclass.Applicative
  alias Elixirdo.Typeclass.Profunctor
  alias Elixirdo.Typeclass.Choice
  alias Elixirdo.Function
  alias Elixirdo.Either

  def prism(bt, s_either_ta) do
    #  functor:fmap(BT) :: f b -> f t
    #  applicative:pure(_) :: t -> f t
    #  either:either(applicative:pure(_), functor:fmap(BT)) :: Either t (f b) -> f t
    #  SETA :: s -> Either t a
    #  dimap(SETA, either) :: p (Either t a) (Either t (f b)) -> p s -> f t
    #  right :: p a (f b) -> p (Either t a) (Either t (f b))
    #  final type is p a (f b) -> p s (f t)
    Function.compose(
      Profunctor.dimap(
        s_either_ta,
        Either.either(fn a -> Applicative.pure(a) end, fn fa ->
          Functor.fmap(bt, fa)
        end)
      ),
      fn c -> Choice.right(c) end
    )
  end
end
