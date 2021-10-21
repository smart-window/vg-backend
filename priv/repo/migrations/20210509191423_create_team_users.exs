defmodule Velocity.Repo.Migrations.CreateTeamUsers do
  use Ecto.Migration

  def change do
    create table(:team_users) do
      add :team_id, references(:teams, on_delete: :nothing), null: false
      add :user_id, references(:users, on_delete: :nothing), null: false

      timestamps()
    end

    create unique_index(:team_users, [:team_id, :user_id])
    create index(:team_users, [:user_id])
  end
end
