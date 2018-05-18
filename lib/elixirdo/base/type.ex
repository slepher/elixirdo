defmodule Elixirdo.Base.Type do
  alias Elixirdo.Base.Utils

  require Record
  Record.defrecord :cache, Record.extract(:cache, from_lib: "hipe/cerl/erl_types.erl")

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
    :dbg.tracer()
    :dbg.tpl(:type_expansion, :table_find_form, :cx)
    :dbg.p(self(), [:c])
    rec_table = :ets.new(:rec_table, [:protected])
    module_table = :ets.new(:module_table, [:protected])
    type_table = :ets.new(:type_table, [:protected, :bag])
    error_table = :ets.new(:error_table, [:protected, :bag])

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
              case :type_expansion.expand(module, name, arity, rec_table, module_table, type_table, error_table) do
                :error ->
                  acc
                {:ok, type} ->
                  acc = [{module, name, arity, type} | acc]
                  acc
              end
            true ->
              acc
            end
        end, [],
        mfas
      )
    format_error_table(error_table)
    expanded_types
  end

  def format_error_table(error_table) do
    IO.inspect :type_expansion.dialyzer_utils()
    errors = :ets.tab2list(error_table)
    case :ets.tab2list(error_table) do
      [] ->
        :ok
      errors ->
        Enum.map(:ets.tab2list(error_table),
          fn {{module, type, arity}, at_module, line} ->
              Mix.shell.error("type not defined #{module}:#{type}/#{arity} at #{at_module}:#{line}")
            {module, at_module, line} ->
              Mix.shell.error("module could not loaded #{module} at #{at_module}:#{line}")
        end)
        Mix.raise("compile failed")
      end
  end
end
