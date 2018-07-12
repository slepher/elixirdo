defmodule Elixirdo.Base.Typeclass do
  alias Elixirdo.Base.Utils

  @type class(_class, _arguments) :: any()

  import Utils.Macro, only: [with_opts_and_do: 2]

  use Elixirdo.Expand

  defmacro __using__(_) do
    quote do
      alias Elixirdo.Base.Typeclass

      import Typeclass,
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
    class_attr = Utils.Parser.parse_class(name)

    [class: class_name, class_param: class_param, extends: typeclass_keyword] = Keyword.take(class_attr, [:class, :class_param, :extends])
    typeclasses = :ordsets.from_list([class_param | Keyword.keys(typeclass_keyword)])

    module = __CALLER__.module
    Module.put_attribute(module, :class_name, class_name)
    Module.put_attribute(module, :class_param, class_param)
    Module.put_attribute(module, :typeclasses, typeclasses)
    Module.put_attribute(module, :typeclass_keyword, typeclass_keyword)
    Module.put_attribute(module, :functions, [])
    block = Elixirdo.Base.Utils.Macro.rename_macro(:def, :__defclass_def, block)
    quote do
      @elixirdo_typeclass unquote(class_name)
      unquote(using_quote(module, class_name))
      unquote(block)
      Elixirdo.Base.Typeclass.typeclass_macro(unquote(class_name))
    end
  end

  defmacro typeclass_macro(class_name) do
    module = __CALLER__.module
    functions = Module.get_attribute(module, :functions)
    Elixirdo.Base.Utils.Macro.export_attribute(module, class_name, module: module, functions: functions)
  end

  defmacro import_typeclass(typeclass) do
    Utils.Macro.import_attribute_module(__CALLER__, typeclass)
  end

  with_opts_and_do(:__defclass_def, :do_defclass_def)

  def do_defclass_def(def_arguments, other_typeclasses, block, module) do
    class_name = Module.get_attribute(module, :class_name)
    class_param = Module.get_attribute(module, :class_param)
    typeclasses = Module.get_attribute(module, :typeclasses)

    other_typeclasses = other_typeclasses |> Enum.map(fn {key, value} -> {key, Utils.Parser.unwrap_term(value)} end)

    def_spec = Utils.Parser.parse_def(def_arguments, typeclasses, block != nil)

    %{name: name, arguments: type_args, return: type_return} = def_spec
    arity = length(type_args)
    Utils.Macro.update_attribute(module, :functions, fn functions -> [{name, arity} | functions] end)

    arg_offsets = :lists.seq(1, arity)

    lens_attrs_args = type_args |> Enum.map(&Utils.Lens.lens_attrs_of_type/1)

    args = Utils.Macro.gen_vars(arg_offsets, "argument")

    quote do
      Kernel.def unquote(name)(unquote_splicing(args), arg_type \\ unquote(class_name)) do
        unquote(
          with_return(
            type_return,
            fn return_lens_attrs_args, return_args, final_return_type ->
              return_quote =
                quote do
                  module.unquote(name)(unquote_splicing(args), type)
                end

              args_with_lens_attrs = List.zip([args ++ :lists.flatten(return_args), lens_attrs_args ++ return_lens_attrs_args])

              first_args_with_lens_attrs = args_with_lens_attrs |> first_lens_attrs_args()
              rest_args_with_lens_attrs = args_with_lens_attrs |> rest_lens_attrs_args()

              mapping_arguments first_args_with_lens_attrs, class_param, Utils.Type.escape(final_return_type, [{class_param, class_name}|other_typeclasses]) do
                quote do
                  unquote_splicing(
                    trans_lens_attrs_vars(
                      rest_args_with_lens_attrs,
                      quote(do: type),
                      class_param
                    )
                  )

                  type_name = Elixirdo.Base.Generated.type_name(type)
                  module = Elixirdo.Base.Generated.module(type_name, unquote(class_name))
                  unquote_splicing(trans_return(return_quote, :lists.reverse(return_args)))
                end
              end
            end
          )
        )
      end

      unquote_splicing(default_impl(name, class_param, def_spec, block))
    end
  end

  def using_quote(module, typeclass) do
    typeclass_key = String.to_atom("import_" <> Atom.to_string(typeclass))

    quote do
      def __using_import__(opts) do
        module = unquote(module)
        typeclass = unquote(typeclass)
        import_typeclass = Keyword.get(opts, unquote(typeclass_key), false)
        import_all_typeclass = Keyword.get(opts, :import_typeclasses, false)

        case import_typeclass or import_all_typeclass do
          true ->
            [
              quote do
                import_typeclass unquote(module).unquote(typeclass)
              end
            ]

          false ->
            []
        end
      end
    end
  end

  def trans_return(expr, []) do
    [expr]
  end

  def trans_return(expr, [args | t]) do
    [
      quote do
        return = unquote(expr)
      end
      | trans_return(
          quote do
            return.(unquote_splicing(args))
          end,
          t
        )
    ]
  end

  def with_return(type, callback) do
    with_return(type, "return", callback)
  end

  def with_return(%Utils.Type{type: %Utils.Type.Function{arguments: type_fn_args, return: type_return}}, return_var, callback) do
    arity = length(type_fn_args)
    args = Utils.Macro.gen_vars(:lists.seq(1, arity), return_var <> "_arg")
    return_var = return_var <> "_return"
    lens_attrs_args = type_fn_args |> Enum.map(&Utils.Lens.lens_attrs_of_type/1)

    quote do
      fn unquote_splicing(args) ->
        unquote(
          with_return(type_return, return_var, fn lens_attr_args_acc, args_acc, type ->
            callback.(lens_attrs_args ++ lens_attr_args_acc, [args | args_acc], type)
          end)
        )
      end
    end
  end

  def with_return(%Utils.Type{} = type, _return_var, callback) do
    callback.([], [], type)
  end

  def mapping_arguments(args_with_lens_attrs, class_param, return_type, do: block) do
    args_with_lens_attrs = args_with_lens_attrs |> Enum.filter(fn {_, attrs} -> attrs != [] end)

    case args_with_lens_attrs do
      [] ->
        quote do
          Elixirdo.Base.Undetermined.new(
            fn type ->
              unquote(block)
            end,
            arg_type, unquote(Macro.escape(return_type))
          )
        end

      _ ->
        {args, rest_args, rest_lens_attrs_args} =
          args_with_lens_attrs
          |> Enum.reduce(
            {[], [], []},
            fn
              {arg, [{^class_param, []}]}, {args_acc, rest_args_acc, rest_lens_attr_args_acc} ->
                {[arg | args_acc], rest_args_acc, rest_lens_attr_args_acc}

              {arg, lens_attr_arg}, {args_acc, rest_args_acc, rest_lens_attr_args_acc} ->
                {args_acc, [arg | rest_args_acc], [lens_attr_arg | rest_lens_attr_args_acc]}
            end
          )

        case rest_args do
          [] ->
            quote do
              Elixirdo.Base.Undetermined.map_list(
                fn [unquote_splicing(args)], type ->
                  unquote(block)
                end,
                [unquote_splicing(args)],
                arg_type, unquote(Macro.escape(return_type))
              )
            end

          _ ->
            {attrs_lenses, rattrs_lenses, init} = rcompose_attributes(rest_lens_attrs_args, class_param)

            unmap_quote =
              quote do
                {unquote_splicing(rest_args)} = Elixirdo.Base.Utils.Lens.set(lens, mapped, {unquote_splicing(rest_args)})
              end

            mapped_quote =
              case args do
                [] ->
                  quote do
                    mapped
                  end

                _ ->
                  quote do
                    [unquote_splicing(args) | mapped]
                  end
              end

            quote do
              lens = Elixirdo.Base.Utils.Lens.rcomposes_attrs(unquote(attrs_lenses), unquote(rattrs_lenses), unquote(init))
              mapped = Elixirdo.Base.Utils.Lens.view(lens, {unquote_splicing(rest_args)})

              Elixirdo.Base.Undetermined.map_list(
                fn unquote(mapped_quote), type ->
                  (unquote_splicing(Utils.Macro.push(unmap_quote, block)))
                end,
                unquote(mapped_quote),
                arg_type, unquote(Macro.escape(return_type))
              )
            end
        end
    end
  end

  def rcompose_attributes(first_typeclasses_attributes, typeclass) do
    {lens_attributes, rlens_attributes, offset} =
      :lists.foldl(
        fn n, acc0 ->
          typeclass_attributes = :lists.nth(n, first_typeclasses_attributes)
          typeclass_attributes_map = Utils.kvs_to_map(typeclass_attributes)
          attributes_list = Map.get(typeclass_attributes_map, typeclass, [])

          :lists.foldl(
            fn attributes, {accl, accr, incr} ->
              incr = incr + 1
              accl = [[{:tuple, n} | attributes] | accl]
              accr = [[{:list, incr}] | accr]
              {accl, accr, incr}
            end,
            acc0,
            attributes_list
          )
        end,
        {[], [], 0},
        :lists.seq(1, length(first_typeclasses_attributes))
      )

    init = :lists.seq(1, offset) |> Enum.map(fn _ -> nil end)
    {lens_attributes, rlens_attributes, init}
  end

  def first_lens_attrs_args(lens_attrs_args) do
    lens_attrs_args
    |> Enum.map(fn {arg, lens_attrs} ->
      {arg,
       lens_attrs
       |> Enum.filter(fn
         {k, _v} when is_atom(k) ->
           true

         {_k, _v} ->
           false
       end)}
    end)
  end

  def rest_lens_attrs_args(lens_attrs_args) do
    lens_attrs_args
    |> Enum.map(fn {arg, lens_attrs} ->
      {arg,
       lens_attrs
       |> Enum.filter(fn
         {k, _v} when is_atom(k) ->
           false

         {_k, _v} ->
           true
       end)}
    end)
  end

  def trans_lens_attrs_vars(args_with_lens_attrs, class_name, class_param) do
    :lists.filter(
      fn ast -> ast != nil end,
      :lists.map(
        fn {arg, lens_attrs_arg} ->
          trans_lens_attrs_var(lens_attrs_arg, arg, class_name, class_param, false)
        end,
        args_with_lens_attrs
      )
    )
  end

  def trans_lens_attrs_var([], _var_name, _class_var, _class_param, false) do
    nil
  end

  def trans_lens_attrs_var([{type, []}], var, class_var, class_param, is_return) do
    trans_var(type, var, class_var, class_param, is_return)
  end

  def trans_lens_attrs_var(_lens_attrs_var, _var, _class_var, _is_return) do
    # TODO: add complex attributes with lens
    nil
  end

  ## trans variable with type like ((a, f, (a -> f)) -> f) to this form
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
        %Utils.Type.Function{arguments: type_fn_args, return: type_fn_return},
        var,
        class_var,
        class_param,
        is_return
      ) do
    fn_arity = length(type_fn_args)

    fn_args = Utils.Macro.gen_vars(:lists.seq(1, fn_arity), var)

    lens_attrs_fn_args = type_fn_args |> Enum.map(&Utils.Lens.lens_attrs_of_type/1)

    %Utils.Type{type: type_fn_return} = type_fn_return

    fn_args_with_lens_attrs = List.zip([fn_args, lens_attrs_fn_args])

    fn_return = Utils.Macro.gen_var("return", var)

    var_expression =
      quote do
        fn unquote_splicing(fn_args) ->
          unquote_splicing(
            trans_lens_attrs_vars(
              fn_args_with_lens_attrs,
              class_var,
              class_param
            )
          )

          unquote(fn_return) = unquote(var).(unquote_splicing(fn_args))

          unquote(trans_var(type_fn_return, fn_return, class_var, class_param, true))
        end
      end

    quote_assign(var, var_expression, is_return)
  end

  def trans_var(class_param, var, class_var, class_param, is_return) do
    var_expression =
      quote do
        Elixirdo.Base.Undetermined.run(unquote(var), unquote(class_var))
      end

    quote_assign(var, var_expression, is_return)
  end

  def trans_var(_var_type, var, _class_var, _class_param, true) do
    var
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
      params = Map.get(def_spec, :argument_vars)
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

  def extract_elixirdo_typeclasses(paths) do
    classes =
      Utils.File.extract_matching_by_attribute(paths, 'Elixir.', fn _module, attributes ->
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
