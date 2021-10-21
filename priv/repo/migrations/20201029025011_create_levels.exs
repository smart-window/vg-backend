defmodule Velocity.Repo.Migrations.CreateLevels do
  use Ecto.Migration

  def change do
    create table(:levels) do
      add :accrual_policy_id, references(:accrual_policies), null: false
      add :start_date_interval, :integer
      add :start_date_interval_unit, :string
      add :pega_level_id, :string
      add :accrual_amount, :float
      add :accrual_frequency, :float
      add :accrual_period, :string
      add :max_days, :float
      add :carryover_limit_type, :string
      add :carryover_limit, :float
      add :accrual_calculation_month_day, :string
      add :accrual_calculation_week_day, :integer
      add :accrual_calculation_year_month, :string
      add :accrual_calculation_year_day, :integer

      timestamps(default: fragment("now()"))
    end

    create(unique_index(:levels, :pega_level_id))
  end
end
