defmodule Velocity.Schema.Team do
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.TeamCountry
  alias Velocity.Schema.TeamRegion
  alias Velocity.Schema.TeamTag
  alias Velocity.Schema.TeamUser

  schema "teams" do
    field :name, :string
    field :parent_id, :id

    has_many :team_tags, TeamTag
    has_many :tags, through: [:team_tags, :tag]

    has_many :team_countries, TeamCountry
    has_many :countries, through: [:team_countries, :country]

    has_many :team_regions, TeamRegion
    has_many :regions, through: [:team_regions, :region]

    has_many :team_users, TeamUser
    has_many :users, through: [:team_users, :user]

    timestamps()
  end

  @doc false
  def changeset(team, attrs) do
    team
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
