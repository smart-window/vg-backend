defmodule Velocity.Repo.Migrations.RenameNotificationsGroupsToRoles do
  use Ecto.Migration

  def up do
    rename table(:notification_defaults), :groups, to: :roles
  end

  def down do
    rename table(:notification_defaults), :roles, to: :groups
  end
end
