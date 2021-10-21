defmodule Velocity.Repo.Migrations.CreateRolePermissions do
  use Ecto.Migration

  def change do
    create table(:role_permissions) do
      add :permission_id, references(:permissions), null: false
      add :role_id, references(:roles), null: false

      timestamps()
    end

    create(unique_index(:role_permissions, [:permission_id, :role_id]))
  end
end
