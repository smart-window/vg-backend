defmodule Velocity.Repo.Migrations.CreatePartnerManagers do
  use Ecto.Migration

  def change do
    create table(:partner_managers) do
      add :job_title, :string
      add :partner_id, references(:partners, on_delete: :nothing), null: false
      add :user_id, references(:users, on_delete: :nothing), null: false

      timestamps()
    end

    create unique_index(:partner_managers, [:partner_id, :user_id])
    create index(:partner_managers, [:user_id])
  end
end
