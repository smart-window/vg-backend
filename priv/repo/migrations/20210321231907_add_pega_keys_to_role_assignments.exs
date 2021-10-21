defmodule Velocity.Repo.Migrations.AddPegaKeysToRoleAssignments do
  use Ecto.Migration

  def change do
    alter table(:role_assignments) do
      add :pega_pk, :string
      add :pega_ak, :string
    end
  end
end
