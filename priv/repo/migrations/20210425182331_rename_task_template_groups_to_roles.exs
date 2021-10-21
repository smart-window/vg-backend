defmodule Velocity.Repo.Migrations.RenameTaskTemplateGroupsToRoles do
  use Ecto.Migration

  def up do
    rename table(:task_template_groups), to: table(:task_template_roles)

    alter table(:task_template_roles) do
      remove :group_id
      add :role_id, references(:roles)
    end
  end

  def down do
    rename table(:task_template_roles), to: table(:task_template_groups)

    alter table(:task_template_groups) do
      remove :role_id
      add :group_id, references(:groups)
    end
  end
end
