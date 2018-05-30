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
    quote do
      @elixirdo_type {unquote(name), unquote(arity), true}
    end
  end

  defmacro deftype({:::, _, [{name, _, args}, _type_defs]} = spec) do
    arity = length(args)

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
    :type_expansion.types_and_rec_map(Elixirdo.Maybe) |> IO.inspect(label: "maybe")

    format_errors(errors)
    expanded_types |> IO.inspect()

    expanded_types
    |> Enum.map(fn {_module, name, _arity, type} ->
      {name, :type_formal_trans.to_clauses(type)}
    end)
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
