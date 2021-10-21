defmodule Velocity.Repo.Migrations.AddBankFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :bank_account_holder_name, :string
      add :bank_name, :string
      add :bank_account_number, :integer
      add :bank_account_type, :string
      add :bank_address_id, references(:addresses)
      add :country_of_employment_id, references(:countries)
    end
  end
end
