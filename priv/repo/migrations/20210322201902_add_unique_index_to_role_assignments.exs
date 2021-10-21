defmodule Velocity.Repo.Migrations.AddUniqueIndexToRoleAssignments do
  use Ecto.Migration

  def change do
    create(
      unique_index(:role_assignments, [
        :user_id,
        :role_id,
        :employee_id,
        :country_id,
        :assignment_type,
        :client_id
      ])
    )
  end
end
