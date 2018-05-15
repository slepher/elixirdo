defmodule Elixirdo.Base.Utils do
  def rename_macro(from, to, block) do
    {renamed_ast, _} =
      Macro.traverse(
        block,
        nil,
        fn
          {from_def, ctx, fun}, acc when from_def == from ->
            {{to, ctx, fun}, acc}

          ast, acc ->
            {ast, acc}
        end,
        fn ast, acc ->
          {ast, acc}
        end
      )

    renamed_ast
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

  def var_fn(module, gen_name) when is_function(gen_name) do
    fn pos ->
      name = gen_name.(pos)
      Macro.var(String.to_atom(name <> Integer.to_string(pos)), module)
    end
  end

  def var_fn(module, name) do
    fn pos -> Macro.var(String.to_atom(name <> Integer.to_string(pos)), module) end
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

  def parse_type_param({:->, _, [fn_params, fn_returns]}) do
    {:->, parse_type_params(fn_params), parse_type_param(fn_returns)}
  end

  def parse_type_param([{:->, _, [fn_params, fn_returns]}]) do
    {:->, parse_type_params(fn_params), parse_type_param(fn_returns)}
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

  def extract_matching_by_attribute(paths, prefix, callback) do
    for path <- paths,
        file <- list_dir(path),
        mod = extract_from_file(path, file, prefix, callback),
        do: mod
  end

  def list_dir(path) when is_list(path) do
    case :file.list_dir(path) do
      {:ok, files} -> files
      _ -> []
    end
  end

  def list_dir(path), do: list_dir(to_charlist(path))

  def extract_from_file(path, file, prefix, callback) do
    if :lists.prefix(prefix, file) and :filename.extension(file) == '.beam' do
      extract_from_beam(:filename.join(path, file), callback)
    end
  end

  def extract_from_beam(file, callback) do
    case :beam_lib.chunks(file, [:attributes]) do
      {:ok, {module, [attributes: attributes]}} ->
        callback.(module, attributes)

      _ ->
        nil
    end
  end

  def beams(paths, prefix) do
    for path <- paths,
        file <- list_dir(path),
        :filename.extension(file) == '.beam',
        :lists.prefix(prefix, file),
        do: :filename.join(path, file)
  end
end
