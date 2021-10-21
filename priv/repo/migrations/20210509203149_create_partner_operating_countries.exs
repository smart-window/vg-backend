defmodule Velocity.Repo.Migrations.CreatePartnerOperatingCountries do
  use Ecto.Migration

  def change do
    create table(:partner_operating_countries) do
      add :partner_id, references(:partners, on_delete: :nothing), null: false
      add :country_id, references(:countries, on_delete: :nothing), null: false

      timestamps()
    end

    create unique_index(:partner_operating_countries, [:partner_id, :country_id])
    create index(:partner_operating_countries, [:country_id])
  end
end
