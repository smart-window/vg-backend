defmodule Velocity.Repo.Migrations.CreateTeams do
  use Ecto.Migration

  def change do
    create table(:teams) do
      add :name, :string, null: false
      add :parent_id, references(:teams, on_delete: :nothing)

      timestamps()
    end

    create index(:teams, [:parent_id])
  end
end
