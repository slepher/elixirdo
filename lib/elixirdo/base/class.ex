defmodule Elixirdo.Typeclass.Class do

  defmacro def({name, _, args}) when is_atom(name) and is_list(args) do
    arity = length(args)

    type_args = :lists.map(fn _ -> quote(do: term) end, :lists.seq(2, arity))
    type_args = [quote(do: t) | type_args]

    varify = fn pos -> Macro.var(String.to_atom("var" <> Integer.to_string(pos)), __MODULE__) end

    call_args = :lists.map(varify, :lists.seq(2, arity))
    call_args = [quote(do: term) | call_args]

    quote do
      name = unquote(name)
      arity = unquote(arity)

      @functions [{name, arity} | @functions]

      # Generate a fake definition with the user
      # signature that will be used by docs
      Kernel.def(unquote(name)(unquote_splicing(args)))

      # Generate the actual implementation
      Kernel.def unquote(name)(unquote_splicing(call_args)) do
        impl_for!(term).unquote(name)(unquote_splicing(call_args))
      end

      # Convert the spec to callback if possible,
      # otherwise generate a dummy callback
      Module.spec_to_callback(__MODULE__, {name, arity}) ||
        @callback unquote(name)(unquote_splicing(type_args)) :: term
    end
  end

  defmacro def(_) do
    raise ArgumentError, "invalid arguments for def inside defprotocol"
  end
end
