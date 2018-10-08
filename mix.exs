defmodule Call.MixProject do
  use Mix.Project

  def project do
    [
      app: :call,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      applications: [:cowboy, :plug, :httpoison, :amqp, :timex],
      extra_applications: [:logger],
      mod: {Call.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:poison, "~> 3.1"},
      {:amqp, "~> 1.0"},
      {:cowboy, "~> 2.4"},
      {:plug, "~> 1.6"},
      {:httpoison, "~> 1.1"},
      {:dapnet_service, github: "dapnet-core/elixir-dapnet-service"},
      {:timex, "~> 3.3"},
      {:ex_json_schema, "~> 0.5.4"},
      {:elixir_uuid, "~> 1.2"},
      {:ranch_proxy_protocol, "~> 2.0", override: true}
    ]
  end
end
