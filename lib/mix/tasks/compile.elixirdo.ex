defmodule Mix.Tasks.Compile.Elixirdo do
  use Mix.Task.Compiler

  @manifest "compile.elixirdo"

  def run(_args) do
    config = Mix.Project.config()
    Mix.Task.run("compile")
    # {opts, _, _} = OptionParser.parse(args, switches: [force: :boolean, verbose: :boolean])

    # manifest = manifest()

    case config[:consolidate_protocols] do
      true ->
        output = Mix.Project.compile_path(config)

        paths = consolidation_paths()

        type_function = Elixirdo.Base.Type.extract_elixirdo_types(paths)
        typeclass_function = Elixirdo.Base.Typeclass.extract_elixirdo_typeclasses(paths)
        instance_function = Elixirdo.Base.Instance.extract_elixirdo_instances(paths)
        generate_module(output, type_function, typeclass_function, instance_function)
        :ok

      false ->
        :ok
    end
  end

  def clean() do
    config = Mix.Project.config()
    output = Mix.Project.compile_path(config)
    module = Elixir.Elixirdo.Base.Generated
    file = Path.join(output, "#{module}.beam")
    File.rm!(file)
  end

  def manifests, do: [manifest()]
  defp manifest, do: Path.join(Mix.Project.manifest_path(), @manifest)

  defp consolidation_paths do
    filter_otp(:code.get_path(), :code.lib_dir())
  end

  defp filter_otp(paths, otp) do
    Enum.filter(paths, &(not :lists.prefix(&1, otp)))
  end

  def generate_module(output, type_function, typeclass_function, instance_function) do
    File.mkdir_p!(output)

    content =
      quote do
        defmodule Elixirdo.Base.Generated do
          unquote(type_function)
          unquote(typeclass_function)
          unquote(instance_function)
        end
      end

    # type_function |> Macro.to_string |> IO.puts
    # typeclass_function |> Macro.to_string |> IO.puts
    # instance_function |> Macro.to_string |> IO.puts

    Code.compiler_options(ignore_module_conflict: true)
    [{module, binary}] = Code.compile_quoted(content)
    Code.compiler_options(ignore_module_conflict: false)

    File.write!(Path.join(output, "#{module}.beam"), binary)
  end
end
