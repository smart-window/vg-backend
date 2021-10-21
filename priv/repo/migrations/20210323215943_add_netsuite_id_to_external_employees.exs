defmodule Velocity.Repo.Migrations.AddNetsuiteIdToExternalEmployees do
  use Ecto.Migration

  def change do
    alter table(:external_employees) do
      add :netsuite_id, :string
    end
  end
end
