defmodule Elixirdo.Base.Utils.Parser do
  alias Elixirdo.Base.Utils.Type


  def parse_class(class) do
    parse_class(class, nil)
  end

  def parse_class({class, _, [{class_param, _, class_arguments} | extends]}, caller) do
    class_attr = parse_class_name(class, caller)
    extends = parse_extends(class_param, merge_argumentlists(extends))
    class_attr ++ [class_param: class_param, class_arguments: class_arguments, extends: extends]
  end

  def parse_extends(class_param, [{extend_param, {extend_class, _, _}} | t]) do
    [{extend_param, extend_class} | parse_extends(class_param, t)]
  end

  def parse_extends(class_param, [{extend_class, _, _} | t]) do
    [{class_param, extend_class} | parse_extends(class_param, t)]
  end

  def parse_extends(_class_param, []) do
    []
  end

  def parse_class_name({:., _, [module, class]}, caller) do
    module = Macro.expand(module, caller)
    [class: class, class_module: module]
  end

  def parse_class_name(class, _caller) when is_atom(class) do
    [class: class, class_module: nil]
  end

  def parse_def({:::, _, [{name, _, arguments}, return]}, typeclasses, with_block) do
    {argument_vars, arguments} = parse_arguments(arguments, with_block)

    type_arguments = parse_types(arguments, typeclasses)
    type_return = parse_type(return, typeclasses)
    %{name: name, argument_vars: argument_vars, arguments: type_arguments, return: type_return}
  end

  def parse_arguments(arguments_with_type, true) do
    arguments_with_type = merge_argumentlists(arguments_with_type)
    new_arguments_with_type =
    :lists.map(
      fn
        {k, v} -> {k, v}
        k when is_atom(k) -> {k, nil}
      end,
      arguments_with_type
    )
    argument_vars = Keyword.keys(new_arguments_with_type)
    arguments = Keyword.values(new_arguments_with_type)
    {argument_vars, arguments}
  end

  def parse_arguments(arguments, false) do
    {nil, arguments}
  end

  def parse_types(types, typeclasses) do
    :lists.map(fn type -> parse_type(type, typeclasses) end, types)
  end

  def parse_type([{:->, ctx, [fn_params, fn_returns]}], typeclasses) do
    parse_type({:->, ctx, [fn_params, fn_returns]}, typeclasses)
  end

  def parse_type({:->, _, [arguments, return]}, typeclasses) do
    type_arguments = parse_types(arguments, typeclasses)
    type_return = parse_type(return, typeclasses)
    fn_typeclasses = Type.typeclasses([type_return|type_arguments])
    %Type{type: %Type.Function{arguments: type_arguments, return: type_return}, typeclasses: fn_typeclasses, outside_typeclasses: []}
  end

  def parse_type({a, b}, typeclasses) do
    parse_type({:{}, [], [a, b]}, typeclasses)
  end

  def parse_type({:{}, _, elements}, typeclasses) do
    type_elements = parse_types(elements, typeclasses)
    tuple_typeclasses = Type.typeclasses(type_elements)
    tuple_outside_typeclasses = Type.outside_typeclasses(type_elements)

    %Type{type: %Type.Tuple{elements: type_elements}, typeclasses: tuple_typeclasses, outside_typeclasses: tuple_outside_typeclasses}
  end

  def parse_type({name, _, _}, typeclasses) when is_atom(name) do
    atom_typeclasses =
      case :ordsets.is_element(name, typeclasses) do
        true ->
          :ordsets.from_list([name])
        false ->
          :ordsets.new()
      end
    %Type{type: name, typeclasses: atom_typeclasses, outside_typeclasses: atom_typeclasses}
  end

  def parse_fn_params({:., _, [dot_left, dot_right]}) do
    parse_fn_params(unwrap_term(dot_left)) ++ [dot_right]
  end

  def parse_fn_params(name) when is_atom(name) do
    [name]
  end

  def unwrap_term({term, _, _}) do
    term
  end

  def unwrap_term(term) when is_atom(term) do
    term
  end

  def merge_argumentlists([h | t]) when is_list(h) do
    h ++ merge_argumentlists(t)
  end

  def merge_argumentlists([h | t]) do
    [h | merge_argumentlists(t)]
  end

  def merge_argumentlists([]) do
    []
  end

end
