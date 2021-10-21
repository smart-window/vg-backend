defmodule Velocity.Repo.Migrations.CreateProcessRoleUsers do
  use Ecto.Migration

  def change do
    create table(:process_role_users) do
      add :process_id, references(:processes), null: false
      add :role_id, references(:roles), null: false
      add :user_id, references(:users), null: false

      timestamps()
    end
  end
end
