defmodule Velocity.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children =
      if Application.get_env(:velocity, :minimal),
        do: [Velocity.Repo],
        else: [
          # Start the Ecto repository
          Velocity.Repo,
          # Start the Telemetry supervisor
          VelocityWeb.Telemetry,
          # Start the PubSub system
          {Phoenix.PubSub, name: Velocity.PubSub},
          # Start the Endpoint (http/https)
          VelocityWeb.Endpoint,
          # Start a worker by calling: Velocity.Worker.start_link(arg)
          # {Velocity.Worker, arg}
          {Absinthe.Subscription, VelocityWeb.Endpoint},
          %{
            id: Exq,
            start: {Exq, :start_link, []}
          }
        ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Velocity.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    VelocityWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
