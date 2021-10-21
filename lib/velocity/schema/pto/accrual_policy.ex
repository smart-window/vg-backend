defmodule Velocity.Schema.Pto.AccrualPolicy do
  @moduledoc """
    Accrual polices are a set of rules that dictate how PTO accrues over time.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Pto.Ledger
  alias Velocity.Schema.Pto.Level
  alias Velocity.Schema.Pto.PtoType

  @fields [
    :pto_type_id,
    :pega_policy_id,
    :label,
    :first_accrual_policy,
    :carryover_day,
    :pool
  ]

  @required_fields [
    :pega_policy_id,
    :first_accrual_policy,
    :carryover_day
  ]

  @first_accrual_policies ["prorate", "pay_in_full"]
  # or this could be a day of the year
  @carryover_days ["anniversary", "first_of_year"]

  @derive {Jason.Encoder, only: @fields ++ [:id]}

  schema "accrual_policies" do
    field :pega_policy_id, :string
    field :label, :string
    field :first_accrual_policy, :string
    field :carryover_day, :string
    field :pool, :string
    has_many :levels, Level, on_delete: :delete_all
    has_many :ledgers, Ledger, on_delete: :nilify_all
    belongs_to :pto_type, PtoType

    timestamps()
  end

  def build(attrs), do: changeset(%__MODULE__{}, attrs)

  def changeset(accrual_policy, attrs) do
    accrual_policy
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> update_change(:first_accrual_policy, &String.downcase/1)
    |> validate_inclusion(:first_accrual_policy, @first_accrual_policies,
      message: "must be one of: #{inspect(@first_accrual_policies)}"
    )
    |> update_change(:carryover_day, &String.downcase/1)
    |> validate_inclusion(:carryover_day, @carryover_days,
      message: "must be one of: #{inspect(@carryover_days)}"
    )
    |> update_change(:pool, &String.downcase/1)
  end

  def required_fields do
    @required_fields
  end
end
