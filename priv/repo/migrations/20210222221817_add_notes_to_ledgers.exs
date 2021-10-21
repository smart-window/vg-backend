defmodule Velocity.Repo.Migrations.AddNotesToLedgers do
  use Ecto.Migration

  def change do
    alter table(:ledgers) do
      add :notes, :text
    end
  end
end
