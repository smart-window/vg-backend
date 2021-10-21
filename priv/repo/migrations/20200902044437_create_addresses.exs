defmodule Velocity.Repo.Migrations.CreateAddresses do
  use Ecto.Migration

  def change do
    create table(:addresses) do
      add :line_1, :string, null: false
      add :line_2, :string
      add :line_3, :string
      add :city, :string
      add :postal_code, :string
      add :county_district, :string
      add :state_province, :string
      add :state_province_iso_alpha_2_code, :string
      add :country_id, references(:countries)
      add :timezone, :string
      add :personal_phone, :string
      add :business_phone, :string
      add :business_email, :string
      add :personal_email, :string

      timestamps()
    end
  end
end
