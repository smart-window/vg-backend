defmodule VelocityWeb.CORS do
  @moduledoc "corsica config"

  # credo:disable-for-this-file Credo.Check.Warning.ApplicationConfigInModuleAttribute
  @allowed_origins Regex.compile!(Application.get_env(:velocity, :cors_allowed_origins_regex))

  use Corsica.Router,
    origins: @allowed_origins,
    allow_credentials: true,
    allow_headers: :all,
    max_age: 600

  resource("/*")
end
