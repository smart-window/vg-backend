defmodule Velocity.Repo.Migrations.CreateUserPolicies do
  use Ecto.Migration

  def change do
    create table(:user_policies) do
      add :user_id, references(:users), null: false
      add :accrual_policy_id, references(:accrual_policies), null: false

      timestamps(default: fragment("now()"))
    end

    create(unique_index(:user_policies, [:user_id, :accrual_policy_id]))
  end
end
