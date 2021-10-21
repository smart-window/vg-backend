defmodule Velocity.Repo.Migrations.CreateTaskTemplateRoleNotifications do
  use Ecto.Migration

  def change do
    create table(:task_template_role_notifications) do
      add :task_template_id, references(:task_templates, on_delete: :nothing)
      add :role_id, references(:roles, on_delete: :nothing)

      timestamps()
    end

    create index(:task_template_role_notifications, [:task_template_id])
    create index(:task_template_role_notifications, [:role_id])
  end
end
