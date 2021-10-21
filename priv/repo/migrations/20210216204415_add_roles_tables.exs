defmodule Velocity.Repo.Migrations.AddRolesTables do
  use Ecto.Migration

  def change do
    create table(:roles) do
      add :slug, :string, null: false
      add :description, :string
      timestamps()
    end

    create(unique_index(:roles, :slug))

    create table(:user_roles) do
      add :user_id, references(:users), null: false
      add :role_id, references(:roles), null: false
      timestamps()
    end

    create(unique_index(:user_roles, [:user_id, :role_id]))

    create table(:role_permissions) do
      add :permission_id, references(:permissions), null: false
      add :role_id, references(:roles), null: false
      timestamps()
    end

    create(unique_index(:role_permissions, [:permission_id, :role_id]))
  end
end
