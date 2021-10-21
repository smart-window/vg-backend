defmodule Velocity.Repo.Migrations.CreateAccrualPolicies do
  use Ecto.Migration

  def change do
    create table(:accrual_policies) do
      add :pega_policy_id, :string, null: false
      add :label, :string
      add :first_accrual_policy, :string
      add :carryover_day, :string
      add :pool, :string

      timestamps(default: fragment("now()"))
    end

    create(unique_index(:accrual_policies, :pega_policy_id))
  end
end
