defmodule Velocity.Repo.Migrations.CreatePartnerOperatingCountryServices do
  use Ecto.Migration

  def change do
    PartnerServiceTypeEnum.create_type()

    create table(:partner_operating_country_services) do
      add :type, PartnerServiceTypeEnum.type(), null: false
      add :fee_type, :string
      add :has_setup_fee, :boolean, default: false, null: false
      add :setup_fee, :float
      add :fee, :float
      add :observation, :string

      add :partner_operating_country_id,
          references(:partner_operating_countries, on_delete: :nothing)

      timestamps()
    end

    create unique_index(:partner_operating_country_services, [
             :partner_operating_country_id,
             :type
           ])
  end
end
