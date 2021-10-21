defmodule Velocity.Schema.TeamCountry do
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Country
  alias Velocity.Schema.Team

  schema "team_countries" do
    belongs_to :team, Team
    belongs_to :country, Country

    timestamps()
  end

  @doc false
  def changeset(team_country, attrs) do
    team_country
    |> cast(attrs, [])
    |> validate_required([])
    |> put_assoc(:team, Map.get(attrs, :team), required: true)
    |> put_assoc(:country, Map.get(attrs, :country), required: true)
  end
end
