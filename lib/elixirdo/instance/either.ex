defmodule Elixirdo.Instance.Either do
  use Elixirdo.Base
  use Elixirdo.Expand

  use Elixirdo.Typeclass.Monad

  defmodule Left do
    @type left(e) :: %Left{value: e}

    defstruct [:value]
    def new(a) do
      %Left{value: a}
    end

    def run(%Left{value: a}) do
      a
    end
  end

  defmodule Right do
    @type right(a) :: %Right{value: a}

    defstruct [:value]

    def new(a) do
      %Right{value: a}
    end

    def run(%Right{value: a}) do
      a
    end
  end

  alias Elixirdo.Instance.Either.Left
  alias Elixirdo.Instance.Either.Right

  deftype either(e, a) :: Left.left(e) | Right.right(a)

  defmacro __using__(_) do
    quote do
      alias Elixirdo.Instance.Either
      alias Elixirdo.Instance.Either.Right
      alias Elixirdo.Instance.Either.Left
    end
  end

  def either(fac, fbc) do
    fn eab ->
      case eab do
        %Left{} = left_a ->
          a = Left.run(left_a)
          fac.(a)
        %Right{} = right_b ->
          b = Right.run(right_b)
          fbc.(b)
      end
    end
  end

  definstance functor(either(e)) do
    def fmap(_f, %Left{} = left_e) do
      left_e
    end

    def fmap(f, %Right{} = right_a) do
      a = Right.run(right_a)
      Right.new(f.(a))
    end
  end

  definstance applicative(either(e)) do
    def pure(a) do
      Right.new(a)
    end

    def ap(%Right{} = right_f, %Right{} = right_a) do
      f = Right.run(right_f)
      a = Right.run(right_a)
      Right.new(f.(a))
    end

    def ap(%Left{} = left_e, _) do
      left_e
    end

    def ap(_, %Left{} = left_e) do
      left_e
    end
  end

  definstance monad(either(e)) do
    def bind(%Left{} = left_e, _afb) do
      left_e
    end

    def bind(%Right{} = right_a, afb) do
      a = Right.run(right_a)
      case afb.(a) do
        %Right{} = right_b ->
          right_b
        %Left{} = left_e ->
          left_e
      end
    end
  end
end
