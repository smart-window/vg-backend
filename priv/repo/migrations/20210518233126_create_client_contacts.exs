defmodule Velocity.Repo.Migrations.CreateClientContacts do
  use Ecto.Migration

  def change do
    create table(:client_contacts) do
      add :client_id, references(:clients, on_delete: :nothing), null: false
      add :user_id, references(:users, on_delete: :nothing), null: true
      add :person_id, references(:persons, on_delete: :nothing), null: true
      add :is_primary, :boolean, null: false

      timestamps()
    end

    create unique_index(:client_contacts, [:client_id, :user_id], where: "user_id is not null")

    create unique_index(:client_contacts, [:client_id, :person_id], where: "person_id is not null")

    create index(:client_contacts, [:user_id], where: "user_id is not null")
    create index(:client_contacts, [:person_id], where: "person_id is not null")
  end
end
