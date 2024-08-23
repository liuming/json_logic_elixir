defmodule JsonLogicExp.Mixfile do
  use Mix.Project

  @version "1.0.0"

  def project do
    [
      app: :json_logic_exponent,
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
      description: "Elixir implementation of JsonLogic, with exponent operator added \"^\"",
      links: %{github: "https://github.com/Anglepoint-Engineering/json_logic_elixir_extended"},
      licenses: ["MIT"]
    }
  end

  defp deps do
    [
      {:decimal, ">= 0.0.0"},
      {:benchee, "~> 1.1", only: :dev},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.2.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.29", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      main: "JsonLogicExp",
      extras: docs_extras(),
      source_ref: "v#{@version}",
      source_url: "https://github.com/Anglepoint-Engineering/json_logic_elixir_extended"
    ]
  end

  defp docs_extras do
    [
      "README.md": [title: "Readme"],
      "CHANGELOG.md": [title: "Changelog"]
    ]
  end
end
