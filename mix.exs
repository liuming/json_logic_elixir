defmodule JsonLogic.Mixfile do
  use Mix.Project

  @version "0.4.0"

  def project do
    [
      app: :json_logic,
      package: package(),
      version: @version,
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    %{
      description: "Elixir implementation of JsonLogic",
      links: %{github: "https://github.com/liuming/json_logic"},
      maintainers: ["Ming Liu"],
      licenses: ["MIT"]
    }
  end

  defp deps do
    [
      {:jason, ">= 1.0.0", optional: true},
      {:poison, ">= 4.0.1", optional: true},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.22", only: :dev, runtime: false}
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
  defp docs do
    [
      main: "JsonLogic",
      extras: docs_extras(),
      source_ref: "v#{@version}",
      source_url: "https://github.com/liuming/json_logic"
    ]
  end

  defp docs_extras do
    [
      "README.md": [title: "Readme"]
    ]
  end
end
