defmodule Velocity.Repo.Migrations.CreateClientTeams do
  use Ecto.Migration

  def change do
    create table(:client_teams) do
      add :client_id, references(:clients, on_delete: :nothing), null: false
      add :team_id, references(:teams, on_delete: :nothing), null: false

      timestamps()
    end

    create unique_index(:client_teams, [:client_id, :team_id])
    create index(:client_teams, [:team_id])
  end
end
