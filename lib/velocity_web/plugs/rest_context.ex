defmodule VelocityWeb.Plugs.RestContext do
  @moduledoc """
  Puts the current user with permissions onto the REST context.
  """
  import Plug.Conn
  @behaviour Plug

  require Logger

  alias Velocity.Contexts.Users
  alias Velocity.Repo

  def init(options), do: options

  def call(conn, _opts) do
    user = Users.get_by(okta_user_uid: conn.assigns[:current_user_okta_uid])
    user_with_permissions = user |> Repo.preload([:permissions, :work_address])

    context =
      if user_with_permissions do
        %{
          current_user: user_with_permissions,
          okta_user_uid: conn.assigns[:current_user_okta_uid]
        }
      else
        %{
          okta_user_uid: conn.assigns[:current_user_okta_uid]
        }
      end

    assign(conn, :context, context)
  rescue
    error ->
      Logger.error(Exception.format(:error, error, __STACKTRACE__))

      conn
      |> put_status(:unauthorized)
      |> put_resp_header("content-type", "application/json")
      |> halt()
      |> send_resp(:unauthorized, Jason.encode!(%{message: :unauthorized}))
  end
end
