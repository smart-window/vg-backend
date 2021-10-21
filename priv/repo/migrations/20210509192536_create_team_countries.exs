defmodule Velocity.Repo.Migrations.CreateTeamCountries do
  use Ecto.Migration

  def change do
    create table(:team_countries) do
      add :team_id, references(:teams, on_delete: :nothing), null: false
      add :country_id, references(:countries, on_delete: :nothing), null: false

      timestamps()
    end

    create unique_index(:team_countries, [:team_id, :country_id])
    create index(:team_countries, [:country_id])
  end
end
