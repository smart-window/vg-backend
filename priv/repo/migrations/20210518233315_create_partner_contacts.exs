defmodule Velocity.Repo.Migrations.CreatePartnerContacts do
  use Ecto.Migration

  def change do
    create table(:partner_contacts) do
      add :partner_id, references(:partners, on_delete: :nothing), null: false
      add :user_id, references(:users, on_delete: :nothing), null: true
      add :person_id, references(:persons, on_delete: :nothing), null: true
      add :country_id, references(:countries, on_delete: :nothing), null: true
      add :is_primary, :boolean, null: false

      timestamps()
    end

    create unique_index(:partner_contacts, [:partner_id, :user_id], where: "user_id is not null")

    create unique_index(:partner_contacts, [:partner_id, :person_id],
             where: "person_id is not null"
           )

    create index(:partner_contacts, [:user_id], where: "user_id is not null")
    create index(:partner_contacts, [:person_id], where: "person_id is not null")
  end
end
