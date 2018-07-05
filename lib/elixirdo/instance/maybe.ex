defmodule Elixirdo.Instance.Maybe do
  use Elixirdo.Base
  use Elixirdo.Expand
  alias Elixirdo.Base.Undetermined

  use Elixirdo.Typeclass.Monad

  defmacro __using__(_) do
    quote do
      alias Elixirdo.Instance.Maybe
      alias Elixirdo.Instance.Maybe.Just
      alias Elixirdo.Instance.Maybe.Nothing
    end
  end

  defmodule Just do
    defstruct [:value]

    def new(a) do
      %Just{value: a}
    end

    def run(%Just{value: a}) do
      a
    end
  end

  defmodule Nothing do
    defstruct []

    def new() do
      %Nothing{}
    end
  end

  alias Elixirdo.Instance.Maybe.Just
  alias Elixirdo.Instance.Maybe.Nothing

  deftype maybe(a) :: %Just{value: a} | %Nothing{}

  definstance functor(maybe) do
    def fmap(f, %Just{} = just_a) do
      a = Just.run(just_a)
      Just.new(f.(a))
    end

    def fmap(_f, %Nothing{}) do
      Nothing.new()
    end
  end

  definstance applicative(maybe) do
    def pure(a) do
      Just.new(a)
    end

    def ap(%Nothing{}, _) do
      Nothing.new()
    end

    def ap(_, %Nothing{}) do
      Nothing.new()
    end

    def ap(%Just{} = just_f, %Just{} = just_a) do
      f = Just.run(just_f)
      a = Just.run(just_a)
      Just.new(f.(a))
    end
  end

  definstance monad(maybe) do
    def return(a) do
      Just.new(a)
    end

    def bind(%Just{} = just_a, afb) do
      a = Just.run(just_a)
      afb.(a)
    end

    def bind(%Nothing{}, _afb) do
      Nothing.new()
    end
  end

  def fail(_e, _ \\ :maybe) do
    :nothing
  end

  def empty(_ \\ :maybe) do
    :nothing
  end

  def unquote(:<|>)(:nothing, mb) do
    mb
  end

  def unquote(:<|>)(ma, _mb) do
    ma
  end

  def mzero(_ \\ :maybe) do
    empty(:maybe)
  end

  def mplus(ma, mb, _ \\ :maybe) do
    Kernel.apply(__MODULE__, :<|>, [ma, mb])
  end

  def run_nargs() do
    0
  end

  def run_m(mA, []) do
    mA
  end

  def run(%Undetermined{} = ua) do
    Undetermined.run(ua, :maybe)
  end

  def run(maybe) do
    maybe
  end
end
