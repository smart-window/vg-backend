defmodule Velocity.Repo.Migrations.AddPtoTypeToAccrualPolicy do
  use Ecto.Migration

  def change do
    alter table(:accrual_policies) do
      # REMINDER: ideally should be null false but that would prevent adding
      # the column so be sure to modify to null false once we backfill
      add :pto_type_id, references(:pto_types), null: true
    end
  end
end
