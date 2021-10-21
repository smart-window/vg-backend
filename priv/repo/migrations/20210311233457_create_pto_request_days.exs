defmodule Velocity.Repo.Migrations.CreatePtoRequestDays do
  use Ecto.Migration

  def change do
    PTOSlotEnum.create_type()

    create table(:pto_request_days) do
      add :pto_request_id, references(:pto_requests), null: false
      add :accrual_policy_id, references(:accrual_policies), null: false
      add :level_id, references(:levels)
      add :pto_type_id, references(:pto_types), null: false
      add :day, :date
      add :slot, PTOSlotEnum.type(), null: false
      add :start_time, :time
      add :end_time, :time

      add :pega_pk, :string
      add :pega_ak, :string

      timestamps()
    end
  end
end
