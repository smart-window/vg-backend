defmodule Velocity.Repo.Migrations.CreateTaskTemplateRoles do
  use Ecto.Migration

  def change do
    create table(:task_template_roles) do
      add :task_template_id, references(:task_templates, on_delete: :nothing)
      add :role_id, references(:roles, on_delete: :nothing)

      timestamps()
    end

    create index(:task_template_roles, [:task_template_id])
    create index(:task_template_roles, [:role_id])
  end
end
