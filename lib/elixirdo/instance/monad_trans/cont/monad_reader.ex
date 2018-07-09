defmodule Elixirdo.Instance.MonadTrans.Cont.MonadReader do
  use Elixirdo.Base
  use Elixirdo.Typeclass.Monad
  use Elixirdo.Typeclass.Monad.Reader, import_typeclass: true

  alias Elixirdo.Instance.MonadTrans.Cont, as: ContT

  import_typeclass MonadReader.monad_reader()
  import_type ContT.cont_t()

  definstance monad_reader(cont_t(s, m), m: monad_reader) do
    def ask() do
      MonadReader.lift_ask(m, cont_t)
    end

    def reader(r) do
      MonadReader.lift_reader(r, m, cont_t)
    end

    def local(f, cont_t_a) do
      ContT.new(fn cc ->
        monad m do
          r <- MonadReader.ask(m)
          MonadReader.local(f, ContT.run(cont_t_a, fn a -> MonadReader.local(fn _ -> r end, cc.(a), m) end), m)
        end
      end)
    end
  end
end
