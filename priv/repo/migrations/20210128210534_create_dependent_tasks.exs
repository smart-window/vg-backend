defmodule Velocity.Repo.Migrations.CreateDependentTasks do
  use Ecto.Migration

  def change do
    create table(:dependent_tasks) do
      add :task_id, references(:tasks, on_delete: :nothing)
      add :dependent_task_id, references(:tasks, on_delete: :nothing)

      timestamps()
    end

    create index(:dependent_tasks, [:task_id])
    create index(:dependent_tasks, [:dependent_task_id])
  end
end
