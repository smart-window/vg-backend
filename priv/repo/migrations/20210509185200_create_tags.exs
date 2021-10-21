defmodule Velocity.Repo.Migrations.CreateTags do
  use Ecto.Migration

  def change do
    create table(:tags) do
      add :name, :string, null: false
      add :parent_id, references(:tags, on_delete: :nothing)

      timestamps()
    end

    create index(:tags, [:parent_id])
  end
end
