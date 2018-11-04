defmodule JsonLogic.Mixfile do
  use Mix.Project

  def project do
    [
      app: :json_logic,
      package: %{
        description: "Elixir implementation of JsonLogic",
        links: %{github: "https://github.com/liuming/json_logic_elixir"},
        maintainers: [ "Ming Liu" ],
        licenses: ["MIT"],
      },
      docs: [main: "JsonLogic", extras: ["README.md"]],
      version: "0.4.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end


  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:poison, "~> 3.1"},
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end
end
