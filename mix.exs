defmodule ExStatsD.Mixfile do
  use Mix.Project

  def project do
    [app: :exstatsd,
     version: "0.1.5",
     elixir: "~> 1.0",
     description: "An Elixir ports client for StatsD",
     package: package,
     deps: deps]
  end

  def application do
    [mod: {ExStatsD.App, []}]
  end

  defp package do
    [ files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["rmusique@gmail.com"],
      licenses: ["MIT"],
      links: %{ "GitHub": "https://github.com/upbit/ExStatsD" } ]
  end

  defp deps do
    [{:exactor, "~> 2.2.0"}]
  end
end
