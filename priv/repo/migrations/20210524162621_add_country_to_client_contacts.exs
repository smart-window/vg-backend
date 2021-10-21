defmodule Velocity.Repo.Migrations.AddCountryToClientContacts do
  use Ecto.Migration

  def change do
    alter table(:client_contacts) do
      add :country_id, references(:countries, on_delete: :nothing), null: true
    end
  end
end
