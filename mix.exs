defmodule JsonLogic.Mixfile do
  use Mix.Project

  @version "0.4.0"

  def project do
    [
      app: :json_logic,
      package: package(),
      aliases: aliases(),
      version: @version,
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp aliases do
    [
      lint: [
        "format --check-formatted",
        "deps.unlock --check-unused",
        "credo --all --strict",
        "dialyzer"
      ]
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
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.2.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.29", only: :dev, runtime: false}
    ]
  end

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
      "README.md": [title: "Readme"],
      "CHANGELOG.md": [title: "Changelog"]
    ]
  end
end
