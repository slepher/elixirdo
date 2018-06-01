defmodule Elixirdo.Base.Type do
  alias Elixirdo.Base.Utils

  require Record
  Record.defrecord(:cache, Record.extract(:cache, from_lib: "hipe/cerl/erl_types.erl"))

  defstruct [:module, :name, :details]

  defmacro __using__(_) do
    quote do
      import Elixirdo.Base.Type, only: [deftype: 1]
      Module.register_attribute(__MODULE__, :elixirdo_type, accumulate: false, persist: true)
    end
  end

  defmacro deftype([{name, arity}]) do
    module = __CALLER__.module
    quote do
      @elixirdo_type {unquote(name), unquote(arity), true}
    end
  end

  defmacro deftype({:::, _, [{name, _, args}, _type_defs]} = spec) do
    arity = length(args)
    module = __CALLER__.module
    Module.put_attribute(module, :elixirdo_typename, name)
    quote do
      @type unquote(spec)
      @elixirdo_type {unquote(name), unquote(arity), false}
      unquote_splicing([do_deftype(name, __CALLER__, spec)])
    end
  end

  def do_deftype(name, caller, _spec) do
    module = caller.module

    quote do
      def type() do
        %Elixirdo.Base.Type{module: unquote(module), name: unquote(name)}
      end
    end
  end

  def extract_elixirdo_types(paths) do
    cache = :type_expansion.cache()

    mfas =
      Utils.extract_matching_by_attribute(paths, 'Elixir.', fn module, attributes ->
        case attributes[:elixirdo_type] do
          nil ->
            nil

          [{type, arity, inner_type}] ->
            {module, type, arity, inner_type}
        end
      end)

    expanded_types =
      :lists.foldl(
        fn {module, name, arity, inner_type}, acc ->
          case inner_type do
            false ->
              case :type_expansion.expand(module, name, arity, cache) do
                :error ->
                  acc

                {:ok, type} ->
                  acc = [{module, name, arity, type} | acc]
                  acc
              end

            true ->
              acc
          end
        end,
        [],
        mfas
      )

    errors = :type_expansion.cache_errors(cache)
    :type_expansion.finalize_cache(cache)

    format_errors(errors)
    quote do
      unquote_splicing(types_to_clauses(expanded_types))
    end
  end

  def types_to_clauses(expanded_types) do
    expanded_types
    |> Enum.map(fn {module, name, _arity, type} ->
        to_clauses(module, name, type)
    end) |> :lists.flatten
  end

  def to_clauses(module, type_name, type) do
    clauses = :type_formal_trans.to_clauses(type)
    clauses |> Enum.map(
      fn {type_var, type_guards} ->
        var = format_var(module, type_var)
        guards = format_guards(module, type_guards)
        if guards do
          quote do
            def type(unquote(var)) when unquote(guards) do
              unquote(type_name)
            end
          end
        else
          quote do
            def type(unquote(var)) do
              unquote(type_name)
            end
          end
        end
      end
    )
  end

  def format_var(module, {:var, 0}) do
    Macro.var(:_, module)
  end

  def format_var(module, {:var, n}) do
    var(module, n, "var")
  end

  def format_var(module, {:tuple, tuples}) do
    formatted_tuples = tuples |> Enum.map(fn tuple -> format_var(module, tuple) end)
    quote do
      {unquote_splicing(formatted_tuples)}
    end
  end

  def format_var(module, {:map, [__struct__: Elixirdo.MaybeT]}) do
    quote do
      %unquote(module){}
    end
  end

  def format_var(_module, var) when is_atom(var) do
    var
  end

  def format_guards(_module, []) do
    nil
  end

  def format_guards(module, [guard|guards]) do
    formatted_guard = format_guard(module, guard)
    formatted_guards = format_guards(module, guards)
    if formatted_guards do
      quote do
        unquote(formatted_guard) and unquote(formatted_guards)
      end
    else
      formatted_guard
    end
  end

  def format_guard(module, {guard_function, n}) do
    var_name = var(module, n, "var")
    quote do
      unquote(guard_function)(unquote(var_name))
    end
  end

  def var(module, n, prefix) do
    var_name = prefix <> "_" <> Integer.to_string(n)
    Macro.var(String.to_atom(var_name), module)
  end

  def format_errors(errors) do
    case errors do
      [] ->
        :ok
      _ ->
        Enum.map(errors, fn
          {{module, type, arity}, at_module, line} ->
            Mix.shell().error(
              "type not defined #{module}:#{type}/#{arity} at #{at_module}:#{line}"
            )
          {module, at_module, line} ->
            Mix.shell().error("module could not loaded #{module} at #{at_module}:#{line}")
        end)
        Mix.raise("compile failed")
    end
  end
end
