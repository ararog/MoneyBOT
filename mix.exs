defmodule MoneyBOT.Mixfile do
  use Mix.Project

  def project do
    [app: :moneybot,
     version: "0.0.2",
     elixir: "~> 1.0",
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [
      mod: { MoneyBOT, [] },
      applications: [:cowboy, :ranch, :logger]
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:tesla, "~> 1.3.0"},
      {:cowboy, "~> 1.0.0"},
      {:jsx, "~> 2.4.0"},
      {:exjsx, "~> 3.1.0"},
      {:sweet_xml, "~> 0.6.6"}
    ]
  end
end
