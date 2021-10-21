defmodule Velocity.Clients.Okta do
  @moduledoc """
  okta client
  """
  use Tesla

  plug Tesla.Middleware.BaseUrl, Application.get_env(:velocity, :okta_api_host)

  plug Tesla.Middleware.Headers, [
    {"accept", "application/json"},
    {"content-type", "application/json"},
    {"authorization", "SSWS " <> Application.get_env(:velocity, :okta_api_token)}
  ]

  plug Tesla.Middleware.JSON

  @callback list_active_users(String.t()) :: {:ok, map()} | {:error, map()}
  def list_active_users(cursor \\ nil) do
    # 200 is the max limit
    get("/api/v1/users", query: [filter: "status eq \"ACTIVE\"", limit: 200, after: cursor])
  end

  @callback get_user_groups(UUID) :: {:ok, map()} | {:error, map()}
  def get_user_groups(okta_user_uid) do
    get("/api/v1/users/" <> okta_user_uid <> "/groups")
  end

  @callback get_user(String.t()) :: {:ok, map()} | {:error, map()}
  def get_user(login) do
    get("/api/v1/users/" <> URI.encode_www_form(login))
  end

  @callback activate(String.t()) :: {:ok, map()} | {:error, map()}
  def activate(userId) do
    post("/api/v1/users/" <> userId <> "/lifecycle/activate?sendEmail=true", %{})
  end

  @callback reactivate(String.t()) :: {:ok, map()} | {:error, map()}
  def reactivate(userId) do
    post("/api/v1/users/" <> userId <> "/lifecycle/reactivate?sendEmail=true", %{})
  end

  @callback reset_password(String.t()) :: {:ok, map()} | {:error, map()}
  def reset_password(userId) do
    post("/api/v1/users/" <> userId <> "/lifecycle/reset_password?sendEmail=true", %{})
  end
end
