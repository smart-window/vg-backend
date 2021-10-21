defmodule Velocity.Repo.Migrations.AddRoleAssignmentsTables do
  use Ecto.Migration

  def change do
    create table(:role_assignments) do
      add :user_id, references(:users), null: false
      add :role_id, references(:roles), null: false
      add :employee_id, references(:users)
      add :country_id, references(:countries)
      add :company_id, references(:companies)
      add :is_global, :string

      timestamps()
    end
  end
end
