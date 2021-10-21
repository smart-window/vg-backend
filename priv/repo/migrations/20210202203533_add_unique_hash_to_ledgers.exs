defmodule Velocity.Repo.Migrations.AddUniqueHashToLedgers do
  use Ecto.Migration

  def change do
    alter table(:ledgers) do
      add :unique_hash, :string
    end

    create(unique_index(:ledgers, [:unique_hash]))
  end
end
