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
    mfas =
      Utils.extract_matching_by_attribute(paths, 'Elixir.', fn module, attributes ->
        case attributes[:elixirdo_type] do
          nil ->
            nil
          [{type, arity, inner_type}] ->
            {module, type, arity, inner_type}
        end
      end)
    {_, _, expanded_types} =
      :lists.foldl(
        fn {module, name, arity, inner_type}, {modules_loaded, types, acc} ->
        case inner_type do
            false ->
              case :type_expansion.expand(module, name, arity, modules_loaded, types, rec_table) do
                :error ->
                  IO.inspect :ets.tab2list(rec_table)
                  {modules_loaded, types, acc}
                {:ok, {type, modules_loaded, types}} ->
                  acc = [{module, name, arity, type} | acc]
                  {modules_loaded, types, acc}
              end
            true ->
              {modules_loaded, types, acc}
            end
        end,
        {:maps.new(), :sets.new(), []},
        mfas
      )
    expanded_types
  end
end
