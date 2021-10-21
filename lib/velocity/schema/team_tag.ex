defmodule Velocity.Schema.TeamTag do
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Tag
  alias Velocity.Schema.Team
  alias Velocity.Utils.Changesets, as: Utils

  schema "team_tags" do
    belongs_to :team, Team
    belongs_to :tag, Tag

    timestamps()
  end

  @doc false
  def changeset(team_tag, attrs) do
    team_tag
    |> cast(attrs, [])
    |> validate_required([])
    |> Utils.maybe_put_assoc(:team, attrs)
    |> Utils.maybe_put_assoc(:tag, attrs)
  end
end
