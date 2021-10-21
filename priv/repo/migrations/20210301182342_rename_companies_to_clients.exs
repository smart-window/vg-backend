defmodule Velocity.Repo.Migrations.RenameCompaniesToClients do
  use Ecto.Migration

  def change do
    drop constraint(:users, "users_company_id_fkey")
    drop index(:users, [:company_id, :okta_user_uid])

    alter table(:users) do
      remove(:company_id)
    end

    drop constraint(:role_assignments, "role_assignments_company_id_fkey")

    alter table(:role_assignments) do
      remove(:company_id)
    end

    rename table("companies"), to: table("clients")

    alter table(:users) do
      add :client_id, references(:clients)
    end

    alter table(:role_assignments) do
      add :client_id, references(:clients)
    end
  end
end
