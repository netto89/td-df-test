defmodule TdDf.Mixfile do
  use Mix.Project
  alias Mix.Tasks.Phx.Swagger.Generate, as: PhxSwaggerGenerate

  def project do
    [
      app: :td_df,
      version: "2.6.1",
      elixir: "~> 1.4",
      elixirc_paths: elixirc_paths(Mix.env),
      compilers: [:phoenix, :gettext] ++ Mix.compilers,
      start_permanent: Mix.env == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {TdDf.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.3.0"},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_ecto, "~> 3.2"},
      {:postgrex, ">= 0.0.0"},
      {:gettext, "~> 0.11"},
      {:cowboy, "~> 1.0"},
      {:cabbage, git: "https://github.com/eriosv/cabbage.git"},
      {:httpoison, "~> 1.0"},
      {:edeliver, "~> 1.4.5"},
      {:distillery, "~> 1.5", runtime: false},
      {:credo, "~> 0.9.3", only: [:dev, :test], runtime: false},
      {:guardian, "~> 1.0"},
      {:canada, "~> 1.0.1"},
      {:ex_machina, "~> 2.1", only: :test},
      {:corsica, "~> 1.0"},
      {:phoenix_swagger, "~> 0.8.0"},
      {:ex_json_schema, "~> 0.5"},
      {:json_diff, "~> 0.1.0"},
      {:csv, "~> 2.0.0"},
      {:nimble_csv, "~> 0.3"},
      {:codepagex, "~> 0.1.4"},
      {:td_perms, git: "https://github.com/Bluetab/td-perms.git"},
      {:prometheus_ex, "~> 3.0"},
      {:prometheus_plugs, "~> 1.0"},
      {:grafana, git: "https://github.com/BoringButGreat/grafana.git"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "test": ["ecto.create --quiet", "ecto.migrate", "run priv/repo/seeds.exs", "test"],
      "compile": ["compile", &pxh_swagger_generate/1]
    ]
  end

  defp pxh_swagger_generate(_) do
      if Mix.env in [:dev, :prod] do
        PhxSwaggerGenerate.run(["priv/static/swagger.json"])
      end
    end

end
