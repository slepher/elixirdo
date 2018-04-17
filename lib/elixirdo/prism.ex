defmodule Elixirdo.Prism do
  alias Elixirdo.Functor
  alias Elixirdo.Applicative
  alias Elixirdo.Function
  alias Elixirdo.Profunctor
  alias Elixirdo.Either
  alias Elixirdo.Choice

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
        Either.either(fn a -> Applicative.pure(a, :applicative) end, fn fa ->
          Functor.fmap(bt, fa, :functor)
        end),
        :profunctor
      ),
      fn c -> Choice.right(c, :choice) end
    )
  end
end
