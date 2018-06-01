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
      type_expansion(),
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end

  defp type_expansion() do
    if(File.exists?("../type_expansion")) do
      {:type_expansion, in_umbrella: true}
    else
      {:type_expansion, github: "slepher/type_expansion"}
    end
  end
end
