defmodule Call.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    # List all child processes to be supervised
    children = [
      Plug.Adapters.Cowboy2.child_spec(
        scheme: :http,
        plug: Call.Router,
        options: [port: 80]
      ),
      worker(Call.RabbitMQ, [], restart: :permanent),
      worker(Call.Database, [], restart: :permanent),
      worker(DapnetService.CouchDB, [], restart: :permanent),
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Call.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
