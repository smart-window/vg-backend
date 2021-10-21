# credo:disable-for-this-file

require Protocol

Protocol.derive(Jason.Encoder, UndefinedFunctionError,
  only: [:arity, :function, :message, :module, :reason]
)

defmodule VelocityWeb.Controllers.RenderHelpers do
  @moduledoc false
  use VelocityWeb, :controller

  require Logger
  alias Velocity.Utils.Errors, as: Utils

  def render_success(conn, resource) do
    conn
    |> put_status(200)
    |> json(resource)
  end

  def render_error(conn, error) do
    json_error = Utils.mapify_error(error)

    Logger.error("#{inspect(error)}")

    if Regex.match?(
         ~r/no user found|no accrual_policy found|user policy assignment not found|policy not found|UndefinedFunctionError/,
         inspect(error)
       ) do
      conn
      |> put_status(200)
      |> json(%{message: inspect(error)})
    else
      conn
      |> put_status(400)
      |> json(json_error)
    end
  end
end
