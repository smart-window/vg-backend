defmodule VelocityWeb.Controllers.HealthController do
  use VelocityWeb, :controller

  def is_it_up(conn, _params) do
    conn
    |> put_status(200)
    |> json(%{status: "up"})
  end

  def ready(conn, _params) do
    conn
    |> put_status(200)
    |> json(%{status: "ready"})
  end
end
