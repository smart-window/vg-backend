defmodule Velocity.Repo.Migrations.CreateClientOperatingCountries do
  use Ecto.Migration

  def change do
    create table(:client_operating_countries) do
      add :probationary_period_length, :string
      add :notice_period_length, :string
      add :private_medical_insurance, :string
      add :other_insurance_offered, :string
      add :annual_leave, :string
      add :sick_leave, :string
      add :standard_additions_deadline, :string
      add :client_on_faster_reimbursement, :boolean, default: false, null: false
      add :standard_allowances_offered, :string
      add :standard_bonuses_offered, :string
      add :notes, :text
      add :client_id, references(:clients, on_delete: :nothing), null: false
      add :country_id, references(:countries, on_delete: :nothing), null: false

      timestamps()
    end

    create unique_index(:client_operating_countries, [:client_id, :country_id])
    create index(:client_operating_countries, [:country_id])
  end
end
