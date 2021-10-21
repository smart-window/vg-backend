defmodule Velocity.Repo.Migrations.ChangeGroupIndices do
  use Ecto.Migration

  def change do
    # Groups table
    execute "ALTER INDEX roles_slug_index RENAME TO groups_slug_index;"
    execute "ALTER INDEX roles_okta_group_slug_index RENAME TO groups_okta_group_slug_index;"
    execute "ALTER INDEX roles_pkey RENAME TO groups_pkey"
    execute "ALTER SEQUENCE roles_id_seq RENAME TO groups_id_seq;"

    # Group_Permissions table
    execute "ALTER INDEX role_permissions_pkey RENAME TO group_permissions_pkey"

    execute "ALTER INDEX role_permissions_permission_id_role_id_index RENAME TO group_permissions_permission_id_group_id_index"

    execute "ALTER SEQUENCE role_permissions_id_seq RENAME TO group_permissions_id_seq"

    # Task_Template_Group_Notifications table
    execute "ALTER INDEX task_template_role_notifications_pkey RENAME TO task_template_group_notifications_pkey"

    execute "ALTER INDEX task_template_role_notifications_task_template_id_index RENAME TO task_template_group_notifications_task_template_id_index"

    execute "ALTER INDEX task_template_role_notifications_role_id_index RENAME TO task_template_group_notifications_group_id_index"

    execute "ALTER SEQUENCE task_template_role_notifications_id_seq RENAME TO task_template_group_notifications_id_seq"

    # Task_Template_Groups table
    execute "ALTER INDEX task_template_roles_pkey RENAME TO task_template_groups_pkey"

    execute "ALTER INDEX task_template_roles_task_template_id_index RENAME TO task_template_groups_task_template_id_index"

    execute "ALTER INDEX task_template_roles_role_id_index RENAME TO task_template_groups_group_id_index"

    execute "ALTER SEQUENCE task_template_roles_id_seq RENAME TO task_template_groups_id_seq"

    # User_Groups table
    execute "ALTER INDEX user_roles_pkey RENAME TO user_groups_pkey"

    execute "ALTER INDEX user_roles_user_id_role_id_index RENAME TO user_groups_user_id_group_id_index"

    execute "ALTER SEQUENCE user_roles_id_seq RENAME TO user_groups_id_seq"
  end
end
