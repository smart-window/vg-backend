defmodule VelocityWeb.Resolvers.Permissions do
  @moduledoc """
  GQL resolver for permissions
  """

  alias Velocity.Contexts.Okta
  require Logger

  def for_current_user(_args, %{context: %{current_user: current_user}}) do
    {:ok, current_user.permissions}
  end

  def for_current_user(_args, context) do
    uid = context |> Map.get(:context) |> Map.get(:okta_user_uid)

    Logger.error("user not found #{inspect(uid)}")

    Okta.create_user_from_uid(uid)
  end
end
