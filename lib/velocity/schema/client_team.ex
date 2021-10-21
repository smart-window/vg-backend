defmodule Velocity.Schema.ClientTeam do
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Client
  alias Velocity.Schema.Team

  schema "client_teams" do
    belongs_to :client, Client
    belongs_to :team, Team

    timestamps()
  end

  @doc false
  def changeset(client_team, attrs) do
    client_team
    |> cast(attrs, [:client_id, :team_id])
    |> validate_required([:client_id, :team_id])
  end
end
