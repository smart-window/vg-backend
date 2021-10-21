defmodule Velocity.Repo.Migrations.AddLedgerIdToPtoRequestAndDays do
  use Ecto.Migration

  def change do
    alter table(:pto_requests) do
      add :ledger_id, references(:ledgers)
    end

    alter table(:pto_request_days) do
      add :ledger_id, references(:ledgers)
    end
  end
end
