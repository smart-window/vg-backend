defmodule Velocity.Schema.TeamUser do
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Team
  alias Velocity.Schema.User

  schema "team_users" do
    belongs_to :team, Team
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(team_user, attrs) do
    team_user
    |> cast(attrs, [])
    |> validate_required([])
  end
end
