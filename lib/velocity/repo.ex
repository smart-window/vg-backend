defmodule Velocity.Repo do
  use Ecto.Repo,
    otp_app: :velocity,
    adapter: Ecto.Adapters.Postgres
end
