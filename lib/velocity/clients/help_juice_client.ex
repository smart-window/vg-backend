defmodule Velocity.Clients.Helpjuice do
  @moduledoc """
  okta client
  """
  use Tesla

  plug Tesla.Middleware.Headers, [
    {"accept", "application/json"},
    {"content-type", "application/json"},
    {"authorization", Application.get_env(:velocity, :helpjuice_api_token)}
  ]

  plug Tesla.Middleware.BaseUrl, Application.get_env(:velocity, :helpjuice_url)
  plug Tesla.Middleware.Logger

  plug Tesla.Middleware.JSON

  @callback search(String.t()) :: {:ok, map()} | {:error, map()}
  def search(term) do
    get("/api/v3/search", query: [query: term])
  end
end
