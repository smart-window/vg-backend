defmodule Velocity.Repo.Migrations.RenameRolesToGroups do
  use Ecto.Migration

  def up do
    rename table(:roles), to: table(:groups)
    rename table(:user_roles), to: table(:user_groups)
    rename table(:role_permissions), to: table(:group_permissions)
    rename table(:task_template_role_notifications), to: table(:task_template_group_notifications)
    rename table(:task_template_roles), to: table(:task_template_groups)

    rename table(:user_groups), :role_id, to: :group_id
    rename table(:group_permissions), :role_id, to: :group_id
    rename table(:task_template_group_notifications), :role_id, to: :group_id
    rename table(:task_template_groups), :role_id, to: :group_id
    rename table(:notification_defaults), :roles, to: :groups
  end

  def down do
    rename table(:groups), to: table(:roles)
    rename table(:user_groups), to: table(:user_roles)
    rename table(:group_permissions), to: table(:role_permissions)
    rename table(:task_template_group_notifications), to: table(:task_template_role_notifications)
    rename table(:task_template_groups), to: table(:task_template_roles)

    rename table(:user_roles), :group_id, to: :role_id
    rename table(:role_permissions), :group_id, to: :role_id
    rename table(:task_template_role_notifications), :group_id, to: :role_id
    rename table(:task_template_roles), :group_id, to: :role_id
    rename table(:notification_defaults), :groups, to: :roles
  end
end
