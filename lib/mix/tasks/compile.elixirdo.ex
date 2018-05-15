defmodule Mix.Tasks.Compile.Elixirdo do
  use Mix.Task.Compiler

  @manifest "compile.elixirdo"
  @manifest_vsn 1

  def run(args) do
    config = Mix.Project.config()
    Mix.Task.run("compile")
    {opts, _, _} = OptionParser.parse(args, switches: [force: :boolean, verbose: :boolean])

    manifest = manifest()
    output = Mix.Project.compile_path(config)

    paths = consolidation_paths()

    paths |> Elixirdo.Base.Type.extract_elixirdo_types() |> IO.inspect()
    generate_test_module(output)
  end

  def manifest, do: Path.join(Mix.Project.manifest_path(), @manifest)

  defp consolidation_paths do
    filter_otp(:code.get_path(), :code.lib_dir())
  end

  defp filter_otp(paths, otp) do
    Enum.filter(paths, &(not :lists.prefix(&1, otp)))
  end

  def generate_test_module(output) do

    content =
      quote do
        defmodule Elixirdo.Base.Type.Generated do
          def hello() do
            :world
          end
        end
      end

    Code.compiler_options(ignore_module_conflict: true)
    [{module, binary}] = Code.compile_quoted(content)
    Code.compiler_options(ignore_module_conflict: false)

    File.write!(Path.join(output, "#{module}.beam"), binary)
  end
end
