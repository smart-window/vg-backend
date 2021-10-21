defmodule Velocity.Repo.Migrations.ModifiyUniqueHashOnLedgers do
  use Ecto.Migration

  def change do
    drop(unique_index(:ledgers, [:unique_hash]))
    create(unique_index(:ledgers, [:deleted, :unique_hash]))
  end
end
