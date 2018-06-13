defmodule Elixirdo.Base.Typeclass do
  alias Elixirdo.Base.Utils

  @type class(_class, _arguments) :: any()

  defmacro __using__(_) do
    quote do
      alias Elixirdo.Base.TYpeclass

      import Elixirdo.Base.Typeclass,
        only: [
          defclass: 2,
          __defclass_def: 1,
          __defclass_def: 2,
          __defclass_def: 3,
          import_typeclass: 1
        ]
      Module.register_attribute(__MODULE__, :elixirdo_typeclass, accumulate: false, persist: true)
    end
  end

  defmacro defclass(name, do: block) do
    class_attr = Elixirdo.Base.Utils.parse_class(name)

    [class: class_name, class_param: class_param] =
      Keyword.take(class_attr, [:class, :class_param])

    module = __CALLER__.module
    Module.put_attribute(module, :class_name, class_name)
    Module.put_attribute(module, :class_param, class_param)
    Module.put_attribute(module, :functions, [])
    block = Elixirdo.Base.Utils.rename_macro(:def, :__defclass_def, block)

    quote do
      @elixirdo_typeclass unquote(class_name)
      unquote(block)
      Elixirdo.Base.Typeclass.typeclass_macro(unquote(class_name))
    end
  end

  defmacro typeclass_macro(class_name) do
    module = __CALLER__.module
    functions = Module.get_attribute(module, :functions)
    Elixirdo.Base.Utils.export_attribute(module, class_name, [module: module, functions: functions])
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

  defmacro import_typeclass({{:., _, [from_module, typeclass]}, _, _}) do
    module = __CALLER__.module
    from_module = Macro.expand(from_module, __CALLER__)
    Utils.import_attribute(module, from_module, typeclass)
    nil
  end

  def do_defclass_def(params, _opts, block, module) do
    def_spec =
      if block do
        Utils.parse_def(params, true)
      else
        Utils.parse_def(params, false)
      end
    class_name = Module.get_attribute(module, :class_name)
    class_param = Module.get_attribute(module, :class_param)

    [name, param_types, _return_type] =
      Keyword.values(Keyword.take(def_spec, [:name, :type_params, :return_type]))

    arity = length(param_types)
    arities = :lists.seq(1, arity)
    u_arities = match_u_arities(class_param, param_types, arity)

    param_names = :lists.map(fn n -> "var_" <> Integer.to_string(n) end, arities)
    params = :lists.map(fn param -> Macro.var(String.to_atom(param), module) end, param_names)
    u_param_names = :lists.map(fn n -> "u_var_" <> Integer.to_string(n) end, u_arities)
    u_params = :lists.map(fn param -> Macro.var(String.to_atom(param), module) end, u_param_names)
    t_param_names = :lists.map(fn n -> "var_" <> Integer.to_string(n) end, u_arities)
    t_params = :lists.map(fn param -> Macro.var(String.to_atom(param), module) end, t_param_names)

    out_param_names =
      :lists.map(
        fn n ->
          case :lists.member(n, u_arities) do
            true ->
              "u_var_" <> Integer.to_string(n)

            false ->
              "var_" <> Integer.to_string(n)
          end
        end,
        arities
      )

    out_params =
      :lists.map(fn param -> Macro.var(String.to_atom(param), module) end, out_param_names) ++
        [quote(do: u_type \\ unquote(class_name))]

    rest_arities = arities -- u_arities

    default_impl = default_impl(name, class_param, def_spec, block)

    Utils.update_attribute(module, :functions, fn functions -> [{name, arity} | functions] end)

    quote do
      Kernel.def unquote(name)(unquote_splicing(out_params)) do
        Elixirdo.Base.Undetermined.map_list(
          fn [unquote_splicing(t_params)], type ->
            unquote_splicing(
              trans_vars(
                rest_arities,
                param_types,
                param_names,
                quote(do: type),
                class_param,
                module
              )
            )
            type_name = Elixirdo.Base.Generated.type_name(type)
            module = Elixirdo.Base.Generated.module(type_name, unquote(class_name))
            module.unquote(name)(unquote_splicing(params), type)
          end,
          [unquote_splicing(u_params)],
          u_type
        )
      end

      unquote_splicing(default_impl)
    end
  end

  def trans_vars(arities, param_types, param_names, class_name, class_param, module) do
    :lists.filter(
      fn ast -> ast != nil end,
      :lists.map(
        fn n ->
          param_type = :lists.nth(n, param_types)
          param_name = :lists.nth(n, param_names)
          trans_var(param_type, param_name, class_name, class_param, module, false)
        end,
        arities
      )
    )
  end

  ## trans variable with type like (a, f, (a -> f) -> f) to this form
  ## param = fn param_1, param_2, param_3 ->
  ##              param_2 = Undetermined.run(param2, class_name)
  ##              param_3 = fn param_3_1 ->
  ##                           param_3_return = param_3.(param_3_1)
  ##                           Undetermined.run(param_3_return, class_name)
  ##                        end
  ##              param_return = param.(param_1, param_2, param_3)
  ##              Undetermined.run(param_return, class_name)
  ##         end
  def trans_var(
        {:->, fn_param_types, fn_return_type},
        var_name,
        class_var,
        class_param,
        module,
        is_return_var
      ) do
    fn_param_arity = length(fn_param_types)

    fn_param_names =
      :lists.map(
        fn n -> var_name <> "_" <> Integer.to_string(n) end,
        :lists.seq(1, fn_param_arity)
      )

    fn_params =
      :lists.map(
        fn fn_param_name -> Macro.var(String.to_atom(fn_param_name), module) end,
        fn_param_names
      )

    fn_return_name = var_name <> "_return"
    fn_return = Macro.var(String.to_atom(fn_return_name), module)
    var = Macro.var(String.to_atom(var_name), module)

    var_expression =
      quote do
        fn unquote_splicing(fn_params) ->
          unquote_splicing(
            trans_vars(
              :lists.seq(1, fn_param_arity),
              fn_param_types,
              fn_param_names,
              class_var,
              class_param,
              module
            )
          )

          unquote(fn_return) = unquote(var).(unquote_splicing(fn_params))

          unquote(trans_var(fn_return_type, fn_return_name, class_var, class_param, module, true))
        end
      end

    quote_assign(var, var_expression, is_return_var)
  end

  def trans_var(class_param, var_name, class_var, class_param, module, is_return_var) do
    var = Macro.var(String.to_atom(var_name), module)

    var_expression =
      quote do
        Elixirdo.Base.Undetermined.run(unquote(var), unquote(class_var))
      end

    quote_assign(var, var_expression, is_return_var)
  end

  def trans_var(_var_type, _var_name, _class_var, _class_param, _module, false) do
    nil
  end

  def trans_var(_var_type, var_name, _class_var, _class_param, module, true) do
    Macro.var(String.to_atom(var_name), module)
  end

  def quote_assign(var, var_expression, false) do
    quote do
      unquote(var) = unquote(var_expression)
    end
  end

  def quote_assign(_var, var_expression, true) do
    var_expression
  end

  def default_impl(name, class_param, def_spec, block) do
    if block do
      params = Keyword.get(def_spec, :params)
      params = :lists.map(fn param -> Macro.var(param, nil) end, params ++ [class_param])
      name = String.to_atom("__default__" <> Atom.to_string(name))

      [
        quote do
          Kernel.def unquote(name)(unquote_splicing(params)) do
            unquote(block)
          end
        end
      ]
    else
      []
    end
  end

  def match_u_arities(class_param, type_params, arity) do
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

  def match_f_arities(class_param, type_params, arity) do
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

  def extract_elixirdo_typeclasses(paths) do
    classes =
      Utils.extract_matching_by_attribute(paths, 'Elixir.', fn _module, attributes ->
        case attributes[:elixirdo_typeclass] do
          nil ->
            nil

          [type_class] ->
            type_class
        end
      end)

    class_clauses = classes |> Enum.map(fn class -> class_clause(class) end)

    quote do
      unquote_splicing(class_clauses)

      def is_typeclass(_) do
        false
      end
    end
  end

  def class_clause(class_name) do
    quote do
      def is_typeclass(unquote(class_name)) do
        true
      end
    end
  end
end
