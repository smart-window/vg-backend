defmodule Velocity.Repo.Migrations.AlterPartnerContactsUniqueIndex do
  use Ecto.Migration

  def change do
    # alter table(:partner_contacts) do
    drop index(:partner_contacts, [:partner_id, :user_id])

    drop index(:partner_contacts, [:partner_id, :person_id])

    create unique_index(:partner_contacts, [:partner_id, :user_id, :country_id],
             where: "user_id is not null"
           )

    create unique_index(:partner_contacts, [:partner_id, :person_id, :country_id],
             where: "person_id is not null"
           )

    # end
  end
end
