defmodule Velocity.Repo.Migrations.AddPrimaryServiceSecondaryServiceBankChargesToPartnerOperatingCountries do
  use Ecto.Migration

  def change do
    alter table(:partner_operating_countries) do
      add :primary_service, :string, null: true
      add :secondary_service, :string, null: true
      add :bank_charges, :string, null: true
    end
  end
end
