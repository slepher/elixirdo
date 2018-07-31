defmodule Elixirdo.Typeclass.Ord do
  use Elixirdo.Base

  @type ordering() :: :lt | :gt | :eq

  defmacro __using__(opts) do
    quote do
      use Elixirdo.Typeclass.Eq, unquote(opts)
      alias Elixirdo.Typeclass.Ord
      unquote_splicing(__using_import__(opts))
    end
  end

  defclass ord(a, a: eq) do
    def compare(a, a) :: ordering()
  end

  def sort(as) when is_list(as) do
    :lists.sort(
      fn a, b ->
        case compare(a, b) do
          :eq -> true
          :lt -> true
          :gt -> false
        end
      end,
      as
    )
  end
end
