defmodule Velocity.Repo.Migrations.AllowNullForLedgers do
  use Ecto.Migration

  def change do
    alter table(:ledgers) do
      modify :accrual_policy_id, :bigint, null: true
      modify :level_id, :bigint, null: true
    end
  end
end
