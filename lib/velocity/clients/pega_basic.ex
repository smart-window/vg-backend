defmodule Velocity.Clients.PegaBasic do
  @moduledoc """
  okta client
  """
  use Tesla

  plug Tesla.Middleware.BaseUrl, Application.get_env(:velocity, :pega_api_host)

  plug Tesla.Middleware.BasicAuth,
    username: Application.get_env(:velocity, :pega_basic_username),
    password: Application.get_env(:velocity, :pega_basic_password)

  plug Tesla.Middleware.Headers, [
    {"accept", "application/json"},
    {"content-type", "application/json"}
  ]

  plug Tesla.Middleware.JSON

  @callback hire_date_by_okta_uid(String.t()) :: {:ok, map()} | {:error, map()}
  def hire_date_by_okta_uid(okta_uid) do
    get("/prweb/PRRestService/api/v1/data/D_HireDateByOktaID",
      query: [OktaID: okta_uid]
    )
  end
end
