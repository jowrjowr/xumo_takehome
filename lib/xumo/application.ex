defmodule Xumo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      # Xumo.Repo,
      # Start the Telemetry supervisor
      XumoWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Xumo.PubSub},
      Xumo.Assets,
      # Start the Endpoint (http/https)
      XumoWeb.Endpoint
      # Start a worker by calling: Xumo.Worker.start_link(arg)
      # {Xumo.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Xumo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    XumoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
