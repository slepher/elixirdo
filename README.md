# Elixirdo

Elixirdo is a elixir rewritten of Erlando.

# Installation

add deps and compilers options of project to mix.exs

```elixir
def project do
  [
    compilers: Mix.compilers() ++ [:elixirdo]
  ]
end

def deps do
  [
    {:elixirdo, [github: "slepher/elixirdo"]}
  ]
end
```

# typeclass system

## typeclass

  use macro defclass to def typeclass

```elixir
  defclass functor(f) do
  end
```

```elixir
  defclass applicative(f, f: functor) do
  end
```

  use macro def inside defclass to def typeclass functions

```elixir
defmodule Elixirdo.Typeclass.Functor do
  use Elixirdo.Base

  defclass functor(f) do
    def fmap((a -> b), f(a)) :: f(b)
  end
end
```

```elixir
  deflass applicative(f) do
    def pure(a) :: f(a)
    def ap(f((a -> b)), f(a)) :: f(b)
  end
```

  function in typeclass could have default implementations

  key of Keyword in arguments represents variable used in default implementation

```elixir
  defclass applicative(f) do
    def pure(a) :: f(a)

    def ap(applicative_f: f((a -> b)), applicative_a: f(a)) :: f(b) do
      lift_a2(fn fun, x -> fun.(x) end, applicative_f, applicative_a, f)
    end

    def lift_a2(ab_c: (a, b -> c), applicative_a: f(a), applicative_b: f(b)) :: f(c) do
      a_b_c = fn a -> fn b -> ab_c.(a, b) end end
      pure(a_b_c, f) |> ap(applicative_a, f) |> ap(applicative_b, f)
    end
  end
```

  typeclass could have laws

  all implementation of typeclass should match typeclass law

  it should be auto tested while running `mix test`

  TODO: implementation of macro law is not ready yet.

```elixir
  defclass applicative(f, f: functor) do
    law identity(v: f(a)) :: f(a) do
      pure(Function.id()) |> ap(v) === v
    end

    law homomorphism(f: (a -> b), x: a) :: f(b) do
      pure(f) |> ap(pure(x)) === pure(f.(x))
    end

    law interchange(u: f((a -> b)), y: a) :: f(b) do
      u |> ap(pure(y)) === pure(fn f -> fn a -> f.(y, a) end end) |> ap(u)
    end

    law composition(u: f((b -> c)), v: f((a -> b)), w: f(a)) :: f(c) do
      pure(fn f, g -> Function.c(f, g) end) |> ap(u) |> ap(v) |> ap(w) === u |> ap(v |> ap(w))
    end
  end
```

## type

  use macro deftype to def type

  like @type, but you could use typeclass function in type definition

```elixir
defmodule Elixirdo.Instance.MonadTrans.Writer do
  use Elixirdo.Base
  alias Elixirdo.Instance.MonadTrans.Writer, as: WriterT
  defstruct [:data]
  deftype writer_t(w, m, a) :: %WriterT{data: m({a, w()})}
end
```

  all type matches %Writer{} is type writer_t

```elixir
defmodule Elixirdo.Instance.Pair do

  use Elixirdo.Base
  deftype pair(a, b) :: {a, b}
end
```

  all type matches {a, b} is type pair
  TODO: prevent duplicated matches

## instance

  use macro definstance to def implementation of typeclass

```elixir
defmodule Elixirdo.Instance.Pair do
  definstance functor(pair(a, b)) do
   def fmap(f, {m, a}) do
     {m, f.(a)}
   end
  end

  definstance applicative(pair(m, a), m: monoid) do
    def pure(a) do
      {Monoid.mempty(), a}
    end

    def ap({m1, f}, {m2, a}) do
      {Monoid.mappend(m1, m2), f.(a)}
    end
  end
end
```

  def fmap in deftypeclass functor(f) generates two function:

  Functor.fmap/2, Functor.fmap/3

  while calling Functor.fmap(fn a -> a * 2, {:hello, 3})
  
  type is detected by second argument of fmap due to `def fmap((a -> b), f(a)) :: f(b)`

  and call Elixirdo.Instance.Pair.fmap(fn a -> a * 2, {:hello, 3}) returns {:hello, 6}

  in other situations, you could directly call Functor.fmap(f, functor_a, :pair)

  call of Pair.fmap(f, functor_a) is not suggested, unless you know what you are doing

# undetermined

  sometimes return type of function could not directly detected such as:

  `a = Applicative.pure(10)`, `b = Monad.bind(Monad.return(10), &Identity.new/1)`

  for a, type is not determiend, 

  for b, type could not be detected inside function which is &Identity.new/1

  it will return `a = %Undetermined{required_typeclass: :applicative, typeclass: applicative}`

  `b = %Undetermined{required_typeclass: :monad, typeclass: monad}`

  you could use `Undetermined.run(a, :list)`, `Undetermined.run(b, :identity)`

  for existance of undetermined, directly call instance functions may throw exception: `Identity.fmap(f, b)`

  even you already knew `b` is an identity

# monad_transformer

  deftype generate a function with `type_` plus name of type such as `type_reader_t(m)`

  it's return value presents type of reader_t() could be used in typeclass functions like

```elixir
reader_t_state_t_identity = type_reader_t(type_state_t(:identity)) # {:reader_t, {:state_t, :identity}}
Applicative.pure(10, reader_t_state_t_identity)
```

  `m: monad` mentioned in definstance could be used as variable in `def bind(reader_t_a, afb)` 

```elixir
defmodule Elixirdo.Instance.MonadTrans.Reader
  use Elixrido.Base
  use Elixirdo.Typeclass.Monad, import_monad: true

  deftype reader_t(r, m, a) :: %ReaderT{data: (r -> m(a))}
  definstance monad reader_t(r, m), m: monad do
    def bind(reader_t_a, afb) do
      new(
        fn r ->
          monad m do
            a <- run(reader_t_a, r)
            run(afb.(a), r)
          end
        end
      )
    end
  end
end
```

  so the inner type of monad_transformer could be passed 

# monad do

```elixir
  monad m do
    a <- MonadReader.ask()
    Monad.return(a * 2)
  end
```

is same of

```elixir
  MonadReader.ask() |> Monad.bind(fn a -> Monad.return(a * 2) end, m)
```