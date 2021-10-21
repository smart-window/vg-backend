defmodule Velocity.Repo.Migrations.CreateRoleGroupPermissionsView do
  use Ecto.Migration

  def change do
    execute """
      CREATE VIEW view_user_permissions AS
      SELECT permissions.*, users.id AS user_id
      FROM permissions
      INNER JOIN group_permissions ON permissions.id = group_permissions.permission_id
      INNER JOIN groups ON groups.id = group_permissions.group_id
      INNER JOIN user_groups ON user_groups.group_id = groups.id
      INNER JOIN users ON users.id = user_groups.user_id
      UNION
      SELECT permissions.*, users.id AS user_id
      FROM permissions
      INNER JOIN role_permissions ON permissions.id = role_permissions.permission_id
      INNER JOIN roles ON roles.id = role_permissions.role_id
      INNER JOIN user_roles ON user_roles.role_id = roles.id
      INNER JOIN users ON users.id = user_roles.user_id;
    """
  end
end
