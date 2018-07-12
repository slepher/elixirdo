defmodule Elixirdo.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixirdo,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      compilers: Mix.compilers() ++ [:elixirdo],
      dialyzer: [plt_add_apps: [:mix, :hipe, :dialyzer]]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :mix]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      with_umbrella(:type_expansion),
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end

  defp with_umbrella(project_name) do
    with_umbrella(project_name, "slepher")
  end

  defp with_umbrella(project_name, user_name) do
    if(File.exists?("../#{project_name}")) do
      {project_name, [in_umbrella: true]}
    else
      {project_name, [github: "#{user_name}/#{project_name}"]}
    end
  end
end
