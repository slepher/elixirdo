defmodule Elixirdo.Base.Type do
  defmacro __using__(_) do
    quote do
      import Elixirdo.Base.Type, only: [deftype: 1]
    end
  end

  defmacro deftype(type_spec) do
    #type_spec |> IO.inspect(lable: type_spec)
    nil
  end

end
