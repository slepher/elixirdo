defmodule Elixirdo.Base.Utils.Parser do

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

  def parse_def({:::, _, [{name, _, params}, function_returns]}, with_block) do
    results =
      if with_block do
        parse_params_with_type(params)
      else
        [type_params: parse_type_params(params)]
      end

    return_type = parse_type_param(function_returns)
    [name: name, return_type: return_type] ++ results
  end

  def parse_params_with_type(params_with_type) do
    params_with_type = merge_argumentlists(params_with_type)

    new_params_with_type =
      :lists.map(
        fn
          {k, v} -> {k, v}
          k when is_atom(k) -> {k, nil}
        end,
        params_with_type
      )

    params = Keyword.keys(new_params_with_type)
    type_params = Keyword.values(new_params_with_type)
    [params: params, type_params: parse_type_params(type_params)]
  end

  def parse_type_params(type_params) do
    :lists.map(&parse_type_param/1, type_params)
  end

  def parse_type_param({:->, _, [fn_params, fn_returns]}) do
    {:->, parse_type_params(fn_params), parse_type_param(fn_returns)}
  end

  def parse_type_param([{:->, _, [fn_params, fn_returns]}]) do
    {:->, parse_type_params(fn_params), parse_type_param(fn_returns)}
  end

  def parse_type_param({a, b}) do
    {:{}, [parse_type_param(a), parse_type_param(b)]}
  end

  def parse_type_param({:{}, _, tuple_params}) do
    {:{}, parse_type_params(tuple_params)}
  end

  def parse_type_param({name, _, _}) do
    name
  end

  def parse_type_param(name) when is_atom(name) do
    name
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
