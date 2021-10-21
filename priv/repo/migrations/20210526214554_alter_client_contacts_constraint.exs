defmodule Velocity.Repo.Migrations.AlterClientContactsConstraint do
  use Ecto.Migration

  def change do
    drop index(:client_contacts, [:client_id, :user_id])
    drop index(:client_contacts, [:client_id, :person_id])

    create unique_index(:client_contacts, [:client_id, :user_id, :country_id],
             where: "user_id is not null"
           )

    create unique_index(:client_contacts, [:client_id, :person_id, :country_id],
             where: "person_id is not null"
           )
  end
end
