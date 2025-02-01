defmodule Harjus.MixProject do
  @moduledoc """
  Mix project configuration.
  """
  use Mix.Project

  def project do
    [
      app: :harjus,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: [
        test: ["test --no-start", "exclude_integration_tests"],
        quality: [
          "format",
          "credo --strict",
          "compile --all-warnings --warnings-as-errors",
          "test --no-start",
          "include_integration_tests",
          "credo --strict",
          "dialyzer --ignore-exit-status"
        ],
        "quality.ci": [
          "format --check-formatted",
          "credo --strict",
          "compile --all-warnings --warnings-as-errors",
          "test --no-start",
          "include_integration_tests",
          "credo --strict",
          "dialyzer"
        ]
      ],
      dialyzer: [
        paths: ["_build/dev/lib/harjus/ebin", "_build/test/lib/harjus/ebin"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Harjus, []}
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
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:castore, "~> 1.0"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:gen_stage, "~> 1.2.1"},
      {:mutex, "~> 3.0"},
      {:decimal, "~> 2.0"},
      {:telemetry_metrics, "~> 1.0.0"},
      {:telemetry_metrics_prometheus, "~> 1.1.0"},
      {:telemetry_poller, "~> 1.1.0"},
      {:propcheck, "~> 1.4", only: [:test, :dev]},
      {:mox, "~> 1.2.0", only: :test}
    ]
  end

  def cli do
    [
      preferred_envs: [quality: :test, "quality.ci": :test]
    ]
  end

  defp include_integration_tests do
    Mix.shell().info("Including integration tests")
    ExUnit.configure(include: :integration)
  end

  defp exclude_integration_tests do
    Mix.shell().info("Excluding integration tests")
    ExUnit.configure(exclude: :integration)
  end
end
