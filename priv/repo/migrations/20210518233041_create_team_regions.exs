defmodule Velocity.Repo.Migrations.CreateTeamRegions do
  use Ecto.Migration

  def change do
    create table(:team_regions) do
      add :team_id, references(:teams, on_delete: :nothing), null: false
      add :region_id, references(:regions, on_delete: :nothing), null: false

      timestamps()
    end

    create unique_index(:team_regions, [:team_id, :region_id])
    create index(:team_regions, [:region_id])
  end
end
