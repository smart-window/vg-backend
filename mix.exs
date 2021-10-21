defmodule Velocity.MixProject do
  use Mix.Project

  def project do
    [
      app: :velocity,
      version: "0.1.0",
      elixir: "~> 1.1",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Velocity.Application, []},
      extra_applications: [:exponent_server_sdk, :corsica, :logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "priv/Seeds", "test/support"]
  defp elixirc_paths(:dev), do: ["lib", "priv/Seeds", "test/support/factory.ex"]
  defp elixirc_paths(_), do: ["lib", "priv/Seeds", "priv/seeds.exs"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:absinthe_plug, "~> 1.5"},
      {:absinthe, "~> 1.5"},
      {:absinthe_phoenix, "~> 2.0"},
      {:absinthe_relay, "~> 1.5"},
      {:atomic_map, "~> 0.9"},
      {:bamboo, "~> 1.7"},
      {:bamboo_ses, "~> 0.1.0"},
      {:ex_aws, "~> 2.1"},
      {:ex_aws_s3, "~> 2.0"},
      {:excoveralls, "~> 0.10", only: :test},
      {:exponent_server_sdk, "~> 0.2.0"},
      {:exq, "~> 0.14.0"},
      {:castore, "~> 0.1.0"},
      {:corsica, "~> 1.0"},
      {:credo, "~> 1.5.0-rc.2", only: [:dev, :test], runtime: false},
      {:csv, "~> 2.4"},
      {:docusign, "~> 0.3.1"},
      {:ecto_sql, "~> 3.4"},
      {:ex_machina, "~> 2.4", only: [:dev, :test]},
      {:faker, "~> 0.14", only: [:dev, :test]},
      {:gettext, "~> 0.11"},
      {:git_hooks, "~> 0.5.0", only: [:test, :dev], runtime: false},
      {:mint, "~> 1.2.1"},
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false},
      {:mox, "~> 1.0", only: :test},
      {:jason, "~> 1.0"},
      {:joken, "~> 2.2"},
      {:poison, "~> 4.0", override: true},
      {:phoenix_ecto, "~> 4.1"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_dashboard, "~> 0.4"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix, "~> 1.5.7"},
      {:plug_cowboy, "~> 2.0"},
      {:postgrex, ">= 0.0.0"},
      {:telemetry_metrics, "~> 0.4"},
      {:telemetry_poller, "~> 0.4"},
      {:tesla, "~> 1.4.0"},
      {:timex, "~> 3.5"},
      {:ecto_enum, "~> 1.4"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.seed": "run priv/repo/seeds.exs",
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.create", "ecto.migrate"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
