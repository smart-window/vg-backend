defmodule VelocityWeb.HttpClients.Http do
  @moduledoc """
  a dynamic http client that takes in a URL at runtime
  """
  def client(url) do
    middleware = [
      {Tesla.Middleware.BaseUrl, url},
      Tesla.Middleware.JSON
    ]

    Tesla.client(middleware)
  end
end
