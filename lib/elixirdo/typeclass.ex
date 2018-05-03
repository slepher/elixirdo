defmodule Elixirdo.Typeclass do
  defmodule MyMacro do
    defmacro pick(args) do
      IO.inspect args
      nil
    end
  end

  defmodule Example do
    require MyMacro
    def run do
      MyMacro.pick do
        IO.write "dog"
      else
        IO.write "cat"
      after
        IO.puts "!"
      end
    end
  end
end
