defmodule Velocity.Repo.Migrations.CreateLedgers do
  use Ecto.Migration

  def change do
    create table(:ledgers) do
      add(:event_date, :utc_datetime_usec)
      add(:event_type, :string)
      add(:regular_balance, :float)
      add(:regular_transaction, :float)
      add(:carryover_balance, :float)
      add(:carryover_transaction, :float)
      add(:external_case_id, :string)
      add(:user_id, references(:users), null: false)
      add(:accrual_policy_id, references(:accrual_policies), null: false)
      add(:level_id, references(:levels), null: false)

      timestamps(default: fragment("now()"))
    end

    create(unique_index(:ledgers, [:external_case_id]))
    create(index(:ledgers, [:user_id]))
    create(index(:ledgers, [:accrual_policy_id]))
    create(index(:ledgers, ["accrual_policy_id, user_id, event_date DESC"]))
  end
end
