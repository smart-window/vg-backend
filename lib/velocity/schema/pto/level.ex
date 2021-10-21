defmodule Velocity.Schema.Pto.Level do
  @moduledoc """
    levels
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Pto.AccrualPolicy
  alias Velocity.Schema.Pto.Ledger

  @fields [
    :start_date_interval,
    :start_date_interval_unit,
    :pega_level_id,
    :accrual_amount,
    :accrual_period,
    :accrual_frequency,
    :max_days,
    :carryover_limit,
    :carryover_limit_type,
    :accrual_calculation_month_day,
    :accrual_calculation_week_day,
    :accrual_calculation_year_month,
    :accrual_calculation_year_day,
    :accrual_policy_id
  ]

  @required_fields [
    :start_date_interval,
    :start_date_interval_unit,
    :pega_level_id,
    :accrual_amount,
    :accrual_period,
    :accrual_frequency,
    :accrual_policy_id
  ]

  @derive {Jason.Encoder, only: @fields}

  @start_date_interval_units ["days", "weeks", "months", "years"]
  @accrual_periods ["days", "weeks", "months", "years"]

  schema "levels" do
    field :start_date_interval, :integer
    field :start_date_interval_unit, :string
    field :pega_level_id, :string
    field :accrual_amount, :float
    field :accrual_period, :string
    field :accrual_frequency, :float
    field :max_days, :float
    field :carryover_day, :string, virtual: true
    field :carryover_limit, :float
    field :carryover_limit_type, :string
    field :accrual_calculation_month_day, :string
    field :accrual_calculation_week_day, :integer
    field :accrual_calculation_year_month, :string
    field :accrual_calculation_year_day, :integer
    field :effective_date, :date, virtual: true

    belongs_to :accrual_policy, AccrualPolicy
    has_many :ledgers, Ledger, on_delete: :nilify_all
  end

  def build(attrs), do: changeset(%__MODULE__{}, attrs)

  def changeset(accrual_policy, attrs) do
    accrual_policy
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> update_change(:accrual_period, &String.downcase/1)
    |> validate_inclusion(:accrual_period, @accrual_periods,
      message: "must be one of #{inspect(@accrual_periods)}"
    )
    |> update_change(:start_date_interval_unit, &String.downcase/1)
    |> validate_inclusion(:start_date_interval_unit, @start_date_interval_units,
      message: "must be one of: #{inspect(@start_date_interval_units)}"
    )
    |> update_change(:carryover_limit_type, &String.downcase/1)
    |> validate_accrual_periods()
  end

  def required_fields do
    @required_fields
  end

  def validate_accrual_periods(changeset) do
    accrual_period = get_change(changeset, :accrual_period)

    if accrual_period do
      validate_accrual_period(changeset, accrual_period)
    else
      changeset
    end
  end

  defp validate_accrual_period(changeset, "days") do
    changeset
  end

  defp validate_accrual_period(changeset, "weeks") do
    changeset
    |> validate_required([:accrual_calculation_week_day],
      message: "when the accrual period is 'weeks' you must set the accrual_calculation_week_day"
    )
  end

  defp validate_accrual_period(changeset, "months") do
    changeset
    |> validate_required([:accrual_calculation_month_day],
      message:
        "when the accrual period is 'months' you must set the accrual_calculation_month_day"
    )
  end

  defp validate_accrual_period(changeset, "years") do
    changeset
    |> validate_required([:accrual_calculation_year_day, :accrual_calculation_year_month],
      message:
        "when the accrual period is 'years' you must set the accrual_calculation_year_day and accrual_calculation_year_month"
    )
  end
end
