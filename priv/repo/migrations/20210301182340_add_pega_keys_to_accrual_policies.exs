defmodule Velocity.Repo.Migrations.AddPegaKeysToAccrualPolicies do
  use Ecto.Migration

  def change do
    alter table(:accrual_policies) do
      add :pega_pk, :string
      add :pega_ak, :string
    end
  end
end
