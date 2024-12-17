defmodule Kirnu.MixProject do
  use Mix.Project

  def project do
    [
      app: :kirnu,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: [test: "test --no-start"]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Kirnu, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:websockex, "~> 0.4.3"},
      {:req, "~> 0.5.7"},
      {:poison, "~> 6.0"},
      {:dotenv_parser, "~> 2.0"},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false}
    ]
  end
end
