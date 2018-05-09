defmodule Elixirdo.Base.Utils do
  def rename_macro(from, to, block) do
    funs =
      case block do
        nil -> []
        {:__block__, _ctx, funs} -> funs
        fun = {from_def, _ctx, _inner} when from_def == from -> [fun]
      end

    funs
    |> List.wrap()
    |> Enum.map(fn
      {from_def, ctx, fun} when from_def == from ->
        {to, ctx, fun}

      ast ->
        ast
    end)
  end

  defmacro set_attribute(key, value) do
    module = __CALLER__.module
    Module.put_attribute(module, key, value)
    nil
  end

  def update_attribute(module, key, fun) do
    attribute = Module.get_attribute(module, key)
    attribute = fun.(attribute)
    Module.put_attribute(module, key, attribute)
  end

  def get_delete_attribute(module, key) do
    attribute = Module.get_attribute(module, key)
    Module.delete_attribute(module, key)
    attribute
  end

  defmacro set_module_attribute(module, key, value) do
    Module.put_attribute(module, key, value)
  end

  def parse_class({class, _, [{class_param, _, _}]}) do
    [class: class, class_param: class_param, extends: []]
  end

  def parse_class({class, _, [{class_param, _, _} | extends]}) do
    extends = parse_extends(class_param, merge_argumentlists(extends))
    [class: class, class_param: class_param, extends: extends]
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

  def parse_def({:::, _, [function_defs, function_returns]}, with_block) do
    def_opts = parse_function_def(function_defs, with_block)
    return_opts = parse_function_return(function_returns)
    Keyword.merge(def_opts, return_opts)
  end

  def parse_function_def({name, _, params}, with_block) do
    new_params = merge_argumentlists(params)

    results =
      if with_block do
        parse_params_with_type(new_params)
      else
        [type_params: parse_type_params(new_params)]
      end

    [name: name] ++ results
  end

  def parse_function_return({return_type, _, _return_args}) do
    [return_type: return_type]
  end

  def parse_type_params(type_params) do
    :lists.map(&parse_type_param/1, type_params)
  end

  def parse_type_param({:~>, _, [fn_params, fn_returns]}) do
    {:~>, parse_fn_params(unwrap_term(fn_params)), unwrap_term(fn_returns)}
  end

  def parse_type_param([{:->, _, [fn_params, fn_returns]}]) do
    {:~>, parse_type_params(fn_params), unwrap_term(fn_returns)}
  end

  def parse_type_param({name, _, _}) do
    name
  end

  def parse_fn_params({:., _, [dot_left, dot_right]}) do
    parse_fn_params(unwrap_term(dot_left)) ++ [dot_right]
  end

  def parse_fn_params(name) when is_atom(name) do
    [name]
  end

  def parse_params_with_type(params_with_type) do
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

  def merge_argumentlists([h | t]) when is_list(h) do
    h ++ merge_argumentlists(t)
  end

  def merge_argumentlists([h | t]) do
    [h | merge_argumentlists(t)]
  end

  def merge_argumentlists([]) do
    []
  end

  def unwrap_term({term, _, _}) do
    term
  end
end
