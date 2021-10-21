defmodule Velocity.Repo.Migrations.AddSoftDeleteToLedgers do
  use Ecto.Migration

  def change do
    alter table(:ledgers) do
      add :deleted, :boolean, null: false, default: false
    end
  end
end
