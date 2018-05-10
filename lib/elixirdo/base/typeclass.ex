defmodule Elixirdo.Base.Typeclass do
  alias Elixirdo.Base.Utils

  defmacro __using__(_) do
    quote do
      import Elixirdo.Base.Typeclass,
        only: [defclass: 2, __defclass_def: 1, __defclass_def: 2, __defclass_def: 3]
    end
  end

  defmacro defclass(name, do: block) do
    name |> IO.inspect(label: "class")
    class_attr = Elixirdo.Base.Utils.parse_class(name)
    [class: class_name, class_param: class_param, extends: _extends] = class_attr
    module = __CALLER__.module
    Module.put_attribute(module, :class_name, class_name)
    Module.put_attribute(module, :class_param, class_param)
    Module.put_attribute(module, :functions, [])
    block = Elixirdo.Base.Utils.rename_macro(:def, :__defclass_def, block)

    quote do
      unquote(block)

      Elixirdo.Base.Typeclass.typeclass_macro(unquote(class_name), unquote(module))
    end
  end

  defmacro typeclass_macro(class_name, instance_module) do
    module = __CALLER__.module
    functions = Module.get_attribute(module, :functions)
    quote do
      defmacro unquote(class_name)() do
        module = __CALLER__.module
        Module.put_attribute(module, :typeclass_module, unquote(instance_module))
        Module.put_attribute(module, :typeclass_functions, unquote(functions))
        nil
      end
    end
  end

  defmacro __defclass_def(params) do
    do_defclass_def(params, [], nil, __CALLER__.module)
  end

  defmacro __defclass_def(params, do: block) do
    do_defclass_def(params, [], block, __CALLER__.module)
  end

  defmacro __defclass_def(params, opts) do
    {block, new_opts} = Keyword.pop(opts, :do, nil)
    do_defclass_def(params, new_opts, block, __CALLER__.module)
  end

  defmacro __defclass_def(params, opts, do: block) do
    do_defclass_def(params, opts, block, __CALLER__.module)
  end

  def do_defclass_def(params, _opts, block, module) do
    def_spec =
      if block do
        Utils.parse_def(params, true)
      else
        Utils.parse_def(params, false)
      end

    run_def_spec(def_spec, block, module)
  end

  def run_def_spec(def_spec, block, module) do
    class_name = Module.get_attribute(module, :class_name)
    class_param = Module.get_attribute(module, :class_param)

    IO.inspect(def_spec ++ [class_name: class_name, class_param: class_param])

    [name, type_params, _return_type] =
      Keyword.values(Keyword.take(def_spec, [:name, :type_params, :return_type]))

    arity = length(type_params)

    m_arities = match_arities(class_param, type_params, arity)
    u_params = :lists.map(Utils.var_fn(module, "uvar"), m_arities)
    t_params = :lists.map(Utils.var_fn(module, "var"), m_arities)
    params = :lists.map(Utils.var_fn(module, "var"), :lists.seq(1, arity))

    pos_name = fn pos ->
      case :lists.member(pos, m_arities) do
        true ->
          "uvar"
        false ->
          "var"
      end
    end

    out_params =
      :lists.map(Utils.var_fn(module, pos_name), :lists.seq(1, arity)) ++
        [quote(do: class_param \\ unquote(class_name))]

    default_impl = default_impl(name, class_param, def_spec, block)

    Utils.update_attribute(module, :functions, fn functions -> [{name, arity}|functions] end)

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

      unquote(default_impl)
    end
  end

  def default_impl(name, class_param, def_spec, block) do
    if block do
      params = Keyword.get(def_spec, :params)
      params = :lists.map(fn param -> Macro.var(param, nil) end, params ++ [class_param])
      name = String.to_atom("__default__" <> Atom.to_string(name))
      quote do
        Kernel.def unquote(name)(unquote_splicing(params)) do
          unquote(block)
        end
      end
    else
      nil
    end
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
end
