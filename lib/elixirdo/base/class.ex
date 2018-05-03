defmodule Elixirdo.Base.Class do

  defmacro defclass(name, do: block) do
    class_attr = parse_class(name)
    [class: class_name, class_param: class_param, extends: _extends] = class_attr
    block = Elixirdo.Base.Utils.rename_macro(:def, :defi, block)

    quote do
      import Elixirdo.Base.Class, only: [defi: 1, defi: 2, defi: 3]
      import Elixirdo.Base.Utils, only: [set_attribute: 2]

      # why use macro?
      # let Module.put_attribute evaluate before block
      # it returns nil so expands nothing
      set_attribute(:class_name, unquote(class_name))
      set_attribute(:class_param, unquote(class_param))
      unquote(block)
    end
  end

  defmacro defi(params) do
    class_def(params, [], nil, __CALLER__.module)
  end

  defmacro defi(params, do: block) do
    class_def(params, [], block, __CALLER__.module)
  end

  defmacro defi(params, opts) do
    {block, new_opts} = Keyword.pop(opts, :do, nil)
    class_def(params, new_opts, block, __CALLER__.module)
  end

  defmacro defi(params, opts, do: block) do
    class_def(params, opts, block, __CALLER__.module)
  end

  def class_def(params, _opts, block, module) do
    def_spec =
      if block do
        parse_def(params, true)
      else
        parse_def(params, false)
      end
    run_def_spec(def_spec, module)
  end

  def run_def_spec(def_spec, module) do
    class_name = Module.get_attribute(module, :class_name)
    class_param = Module.get_attribute(module, :class_param)

    [name, type_params, _return_type] =
      Keyword.values(Keyword.take(def_spec, [:name, :type_params, :return_type]))

    arity = length(type_params)

    m_arities = match_arities(class_param, type_params, arity)
    u_params = :lists.map(var_fn(module, "uvar"), m_arities)
    t_params = :lists.map(var_fn(module, "var"), m_arities)
    params = :lists.map(var_fn(module, "var"), :lists.seq(1, arity))

    pos_name = fn pos ->
      case :lists.member(pos, m_arities) do
        true ->
          "uvar"
        false ->
          "var"
      end
    end

    out_params =
      :lists.map(var_fn(module, pos_name), :lists.seq(1, arity)) ++
        [quote(do: class_param \\ unquote(class_name))]

    quote do
      Kernel.def unquote(name)(unquote_splicing(out_params)) do
        Elixirdo.Base.Undetermined.map_list(
          fn [unquote_splicing(t_params)], class_type ->
            module = Elixirdo.Base.Generated.module(class_type, unquote(class_name))
            module.unquote(name)(unquote_splicing(params))
          end,
          [unquote_splicing(u_params)],
          class_param
        )
      end
    end
  end

  def var_fn(module, gen_name) when is_function(gen_name) do
    fn pos ->
      name = gen_name.(pos)
      Macro.var(String.to_atom(name <> Integer.to_string(pos)), module)
    end
  end

  def var_fn(module, name) do
    fn pos -> Macro.var(String.to_atom(name <> Integer.to_string(pos)), module) end
  end

  def match_arities(class_param, type_params, arity) do
    :lists.reverse(
      :lists.filter(
        fn n ->
          type_param = :lists.nth(n, type_params)
          match_class_param(type_param, class_param)
        end,
        :lists.seq(1, arity)
      )
    )
  end

  def match_class_param(type_param, type_param) do
    true
  end

  def match_class_param(_type_param, _class_param) do
    false
  end

  def parse_class({class, _, [{class_param, _, _}]}) do
    [class: class, class_param: class_param]
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

  @doc false
  def __spec__?(module, name, arity) do
    signature = {name, arity}

    mapper = fn {:spec, expr, pos} ->
      if Kernel.Typespec.spec_to_signature(expr) == signature do
        Module.store_typespec(module, :callback, {:callback, expr, pos})
        true
      end
    end

    specs = Module.get_attribute(module, :spec)
    found = :lists.map(mapper, specs)
    :lists.any(&(&1 == true), found)
  end

  def unwrap_term({term, _, _}) do
    term
  end
end
