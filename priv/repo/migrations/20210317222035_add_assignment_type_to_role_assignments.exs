defmodule Velocity.Repo.Migrations.AddAssignmentTypeToRoleAssignments do
  use Ecto.Migration

  def change do
    RoleAssignmentTypeEnum.create_type()

    alter table(:role_assignments) do
      add :assignment_type, RoleAssignmentTypeEnum.type()
      remove :is_global
    end
  end
end
