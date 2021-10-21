defmodule Velocity.Schema.TeamRegion do
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Region
  alias Velocity.Schema.Team

  schema "team_regions" do
    belongs_to :team, Team
    belongs_to :region, Region

    timestamps()
  end

  @doc false
  def changeset(team_region, attrs) do
    team_region
    |> cast(attrs, [])
    |> validate_required([])
    |> put_assoc(:team, Map.get(attrs, :team), required: true)
    |> put_assoc(:region, Map.get(attrs, :region), required: true)
  end
end
