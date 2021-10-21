defmodule Velocity.Repo.Migrations.CreateTaskAssignments do
  use Ecto.Migration

  def change do
    create table(:task_assignments) do
      add :task_id, references(:tasks, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing)
      add :read_only, :boolean, default: false

      timestamps()
    end

    create index(:task_assignments, [:task_id])
    create index(:task_assignments, [:user_id])
  end
end
