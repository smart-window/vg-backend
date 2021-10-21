defmodule VelocityWeb.Plugs.OktaSimpleToken do
  @moduledoc """
  simple token auth for okta event webhooks
  """
  import Plug.Conn

  require Logger

  def init(options), do: options

  def call(conn, _opts) do
    jwt_token = conn |> get_req_header("authorization") |> List.first()

    if jwt_token && jwt_token == Application.get_env(:velocity, :okta_events_token) do
      conn
    else
      conn
      |> put_status(:unauthorized)
      |> put_resp_header("content-type", "application/json")
      |> halt()
      |> send_resp(:unauthorized, Jason.encode!(%{message: :unauthorized}))
    end
  end

  defmodule Mock do
    @moduledoc "mock of OktaSimpleToken to use in test. this module does not perform any auth"
    def init(options), do: options

    def call(conn, _opts) do
      conn
    end
  end
end
