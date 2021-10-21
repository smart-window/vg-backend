defmodule Velocity.Repo.Migrations.CreatePermissions do
  use Ecto.Migration

  def change do
    create table(:permissions) do
      add :slug, :string, null: false
      add :description, :string

      timestamps()
    end

    create(unique_index(:permissions, :slug))
  end
end
