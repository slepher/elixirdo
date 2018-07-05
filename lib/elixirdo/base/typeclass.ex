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

  def do_defclass_def(def_arguments, _opts, block, module) do
    class_name = Module.get_attribute(module, :class_name)
    class_param = Module.get_attribute(module, :class_param)
    typeclasses = Module.get_attribute(module, :typeclasses)

    def_spec = Utils.Parser.parse_def(def_arguments, typeclasses, block != nil)

    %{name: name, arguments: arguments} = def_spec

    arity = length(arguments)
    argument_offsets = :lists.seq(1, arity)

    arguments_attributes =
      arguments
      |> Enum.map(fn argument ->
        Utils.Lens.lens_of_type(argument)
      end)

    typeclasses_attributes = arguments_attributes |> typeclasses_attributes()

    first_arguments_offsets = first_typeclass_offsets(typeclasses_attributes)
    rest_arguments_offsets = argument_offsets -- first_arguments_offsets

    def_arguments = Utils.Macro.gen_vars(argument_offsets, "argument")
    first_arguments_attributes = Utils.filter_by_offsets(first_arguments_offsets, typeclasses_attributes)
    first_def_arguments = Utils.filter_by_offsets(first_arguments_offsets, def_arguments)

    # quote do
    #   Utils.Lens.view_all_by_type_attributes(unquote(first_typeclasses_attributes), [unquote_splicing(first_def_arguments)])
    # end |> Macro.to_string |> IO.puts

    {attrs_lenses, rattrs_lenses, init} = rcompose_attributes(first_arguments_attributes, class_param)

    def_arguments_with_type = def_arguments ++ [quote(do: argument_type \\ unquote(class_name))]

    default_impl = default_impl(name, class_param, def_spec, block)

    Utils.Macro.update_attribute(module, :functions, fn functions -> [{name, arity} | functions] end)

    quote do
      Kernel.def unquote(name)(unquote_splicing(def_arguments_with_type)) do
        lens = Elixirdo.Base.Utils.Lens.rcomposes_attrs(unquote(attrs_lenses), unquote(rattrs_lenses), unquote(init))
        to_mapped = Elixirdo.Base.Utils.Lens.view(lens, {unquote_splicing(first_def_arguments)})
        Elixirdo.Base.Undetermined.map_list(
          fn mapped, type ->
            {unquote_splicing(first_def_arguments)} = Elixirdo.Base.Utils.Lens.set(lens, {unquote_splicing(first_def_arguments)}, mapped)

            unquote_splicing(
              trans_vars(
                rest_arguments_offsets,
                arguments,
                def_arguments,
                quote(do: type),
                class_param,
                module
              )
            )

            type_name = Elixirdo.Base.Generated.type_name(type)
            module = Elixirdo.Base.Generated.module(type_name, unquote(class_name))
            module.unquote(name)(unquote_splicing(def_arguments), type)
          end,
          to_mapped,
          argument_type
        )
      end

      unquote_splicing(default_impl)
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

  def u_arguments(first_typeclass_offsets, typeclasses_attributes, arguments) do
    first_typeclass_offsets
    |> Enum.map(fn n ->
      argument = :lists.nth(n, arguments)
      typeclass_attributes = :lists.nth(n, typeclasses_attributes)
      {argument, typeclass_attributes}
    end)
  end

  def typeclasses_attributes(arguments_attributes) do
    arguments_attributes
    |> Enum.map(fn attributes ->
      attributes
      |> Enum.filter(fn
        {k, _v} when is_atom(k) ->
          true

        {_k, _v} ->
          false
      end)
    end)
  end

  def first_typeclass_offsets([]) do
    []
  end

  def first_typeclass_offsets(arguments_attributes) do
    :lists.foldl(
      fn n, acc ->
        attributes = :lists.nth(n, arguments_attributes)

        case attributes do
          [] ->
            acc

          _ ->
            [n | acc]
        end
      end,
      [],
      :lists.reverse(Enum.to_list(1..length(arguments_attributes)))
    )
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

  def trans_var(%Utils.Type{typeclasses: []}, _var_name, _class_var, _class_param, _module, false) do
    nil
  end

  def trans_var(
        %Utils.Type{type: %Utils.Type.Function{arguments: fn_param_types, return: fn_return_type}},
        var,
        class_var,
        class_param,
        module,
        is_return_var
      ) do
    fn_param_arity = length(fn_param_types)

    fn_params = Utils.Macro.gen_vars(:lists.seq(1, fn_param_arity), var)

    fn_return = Utils.Macro.gen_var("return", var)

    var_expression =
      quote do
        fn unquote_splicing(fn_params) ->
          unquote_splicing(
            trans_vars(
              :lists.seq(1, fn_param_arity),
              fn_param_types,
              fn_params,
              class_var,
              class_param,
              module
            )
          )

          unquote(fn_return) = unquote(var).(unquote_splicing(fn_params))

          unquote(trans_var(fn_return_type, fn_return, class_var, class_param, module, true))
        end
      end

    quote_assign(var, var_expression, is_return_var)
  end

  def trans_var(%Utils.Type{type: class_param}, var, class_var, class_param, _module, is_return_var) do

    var_expression =
      quote do
        Elixirdo.Base.Undetermined.run(unquote(var), unquote(class_var))
      end

    quote_assign(var, var_expression, is_return_var)
  end

  def trans_var(_var_type, var, _class_var, _class_param, _module, true) do
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

  def match_class_param(%Utils.Type{type: type_param}, type_param) do
    true
  end

  def match_class_param(_type_param, _class_param) do
    false
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
