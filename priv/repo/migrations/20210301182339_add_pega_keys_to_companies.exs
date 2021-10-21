defmodule Velocity.Repo.Migrations.AddPegaKeysToCompanies do
  use Ecto.Migration

  def change do
    alter table(:companies) do
      add :address_id, references(:addresses)
      add :pega_pk, :string
      add :pega_ak, :string
    end
  end
end
