defmodule Velocity.Repo.Migrations.CreateDependentTaskTemplates do
  use Ecto.Migration

  def change do
    create table(:dependent_task_templates) do
      add :task_template_id, references(:task_templates, on_delete: :nothing)
      add :dependent_task_template_id, references(:task_templates, on_delete: :nothing)

      timestamps()
    end

    create index(:dependent_task_templates, [:task_template_id])
    create index(:dependent_task_templates, [:dependent_task_template_id])
  end
end
