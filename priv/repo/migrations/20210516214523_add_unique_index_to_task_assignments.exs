defmodule Velocity.Repo.Migrations.AddUniqueIndexToTaskAssignments do
  use Ecto.Migration

  def up do
    alter table(:task_assignments) do
      add :role_id, references(:roles), null: false
    end

    create index(:task_assignments, [:task_id, :user_id, :role_id], unique: true)
  end

  def down do
    drop index(:task_assignments, [:task_id, :user_id, :role_id], unique: true)

    alter table(:task_assignments) do
      remove :role_id
    end
  end
end
