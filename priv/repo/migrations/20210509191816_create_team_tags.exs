defmodule Velocity.Repo.Migrations.CreateTeamTags do
  use Ecto.Migration

  def change do
    create table(:team_tags) do
      add :team_id, references(:teams, on_delete: :nothing), null: false
      add :tag_id, references(:tags, on_delete: :nothing), null: false

      timestamps()
    end

    create unique_index(:team_tags, [:team_id, :tag_id])
    create index(:team_tags, [:tag_id])
  end
end
