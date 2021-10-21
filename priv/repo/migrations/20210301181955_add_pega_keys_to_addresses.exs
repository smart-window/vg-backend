defmodule Velocity.Repo.Migrations.AddPegaKeysToAddresses do
  use Ecto.Migration

  def change do
    alter table(:addresses) do
      add :pega_pk, :string
      add :pega_ak, :string
    end
  end
end
