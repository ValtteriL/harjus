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
        # exclude integration tests by default
        test: ["test --no-start --exclude integration:true"],
        quality: [
          "format",
          "credo --strict",
          "compile --all-warnings --warnings-as-errors",
          "cmd cmake --build build --config Debug --target all --",
          "cmd ctest -j10 -C Debug -T test --output-on-failure --test-dir build/",
          "test --no-start --include integration:true",
          "credo --strict",
          "dialyzer --ignore-exit-status"
        ],
        "quality.ci": [
          "format --check-formatted",
          "credo --strict",
          "compile --all-warnings --warnings-as-errors",
          "cmd cmake --build build --config Debug --target all --",
          "cmd ctest -j10 -C Debug -T test --output-on-failure --test-dir build/",
          "test --no-start --include integration:true",
          "credo --strict",
          "dialyzer"
        ]
      ],
      dialyzer: [
        paths: ["_build/dev/lib/harjus/ebin", "_build/test/lib/harjus/ebin"]
      ]
    ]
  end

  defp extra_applications(:dev), do: [:wx, :runtime_tools, :observer]
  defp extra_applications(_), do: []

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: extra_applications(Mix.env()) ++ [:logger],
      mod: {Harjus, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:websockex, "~> 0.4.3"},
      {:req, "~> 0.5.7"},
      {:poison, "~> 6.0"},
      {:dotenv_parser, "~> 2.0"},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:castore, "~> 1.0"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:mutex, "~> 3.0"},
      {:decimal, "~> 2.0"},
      {:telemetry_metrics, "~> 1.0.0"},
      {:telemetry_poller, "~> 1.1.0"},
      {:propcheck, "~> 1.4", only: [:test, :dev]},
      {:mox, "~> 1.2.0", only: :test},
      {:telemetry_metrics_cloudwatch, "~> 1.0.0"},
      # hackney, ex_aws required by telemetry_metrics_cloudwatch
      {:hackney, "~> 1.20"},
      {:ex_aws, "~> 2.1"}
    ]
  end

  def cli do
    [
      preferred_envs: [quality: :test, "quality.ci": :test]
    ]
  end
end
