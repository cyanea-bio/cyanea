defmodule Cyanea.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/cyanea-io/cyanea"

  def project do
    [
      app: :cyanea,
      version: @version,
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      name: "Cyanea",
      description: "Open source research data platform for life sciences",
      source_url: @source_url,
      homepage_url: "https://cyanea.dev",
      docs: docs()
    ]
  end

  def application do
    [
      mod: {Cyanea.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Phoenix
      {:phoenix, "~> 1.8"},
      {:phoenix_ecto, "~> 4.6"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.5", only: :dev},
      {:phoenix_live_view, "~> 1.0"},
      {:phoenix_live_dashboard, "~> 0.8"},

      # Database
      {:ecto_sql, "~> 3.12"},
      {:postgrex, ">= 0.0.0"},

      # Background Jobs
      {:oban, "~> 2.18"},

      # Authentication
      {:ueberauth, "~> 0.10"},
      {:ueberauth_orcid, "~> 0.2"},
      {:bcrypt_elixir, "~> 3.0"},
      {:guardian, "~> 2.3"},

      # File Storage
      {:ex_aws, "~> 2.5"},
      {:ex_aws_s3, "~> 2.5"},
      {:sweet_xml, "~> 0.7"},

      # Search
      {:meilisearch, "~> 0.20"},

      # Rust NIFs
      {:rustler, "~> 0.34"},

      # Utilities
      {:jason, "~> 1.4"},
      {:plug_cowboy, "~> 2.7"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.1"},
      {:gettext, "~> 0.26"},
      {:dns_cluster, "~> 0.1.3"},
      {:bandit, "~> 1.5"},
      {:finch, "~> 0.19"},
      {:req, "~> 0.5"},

      # Assets
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      {:heroicons, "~> 0.5"},

      # Development & Testing
      {:floki, ">= 0.36.0", only: :test},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:sobelow, "~> 0.13", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind cyanea", "esbuild cyanea"],
      "assets.deploy": [
        "tailwind cyanea --minify",
        "esbuild cyanea --minify",
        "phx.digest"
      ]
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "LICENSE.md"],
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end
end
