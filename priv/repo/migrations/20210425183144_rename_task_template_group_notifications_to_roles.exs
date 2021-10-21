defmodule Velocity.Repo.Migrations.RenameTaskTemplateGroupNotificationsToRoles do
  use Ecto.Migration

  def up do
    rename table(:task_template_group_notifications), to: table(:task_template_role_notifications)

    alter table(:task_template_role_notifications) do
      remove :group_id
      add :role_id, references(:roles)
    end
  end

  def down do
    rename table(:task_template_role_notifications), to: table(:task_template_group_notifications)

    alter table(:task_template_group_notifications) do
      remove :role_id
      add :group_id, references(:groups)
    end
  end
end
