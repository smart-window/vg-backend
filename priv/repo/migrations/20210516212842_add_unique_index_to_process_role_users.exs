defmodule Velocity.Repo.Migrations.AddUniqueIndexToProcessRoleUsers do
  use Ecto.Migration

  def up do
    create index(:process_role_users, [:process_id, :role_id, :user_id], unique: true)
  end

  def down do
    drop index(:process_role_users, [:process_id, :role_id, :user_id], unique: true)
  end
end
