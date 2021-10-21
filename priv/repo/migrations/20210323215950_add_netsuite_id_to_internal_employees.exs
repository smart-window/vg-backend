defmodule Velocity.Repo.Migrations.AddNetsuiteIdToInternalEmployees do
  use Ecto.Migration

  def change do
    rename table(:internal_employees), :ns_employee_id, to: :netsuite_id
  end
end
