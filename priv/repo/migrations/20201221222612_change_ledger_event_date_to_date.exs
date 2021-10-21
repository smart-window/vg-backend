defmodule Velocity.Repo.Migrations.ChangeLedgerEventDateToDate do
  use Ecto.Migration

  def change do
    alter table(:ledgers) do
      modify :event_date, :date
    end
  end
end
