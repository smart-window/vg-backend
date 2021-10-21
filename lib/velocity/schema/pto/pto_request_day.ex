defmodule Velocity.Schema.Pto.PtoRequestDay do
  @moduledoc "
    schema for PTO request day
    represents a PTO request day for a PTO request
    NOTE: there may be many PTO request days for a given date
    e.g. morning, afternoon, multiple hours slots, etc.
  "
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Pto.AccrualPolicy
  alias Velocity.Schema.Pto.Level
  alias Velocity.Schema.Pto.PtoRequest
  alias Velocity.Schema.Pto.PtoType

  schema "pto_request_days" do
    field :day, :date
    field :slot, PTOSlotEnum
    field :start_time, :time
    field :end_time, :time

    belongs_to :pto_request, PtoRequest
    belongs_to :accrual_policy, AccrualPolicy
    belongs_to :level, Level
    belongs_to :pto_type, PtoType

    timestamps()
  end

  @doc false
  def changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [
      :pto_request_id,
      :accrual_policy_id,
      :level_id,
      :pto_type_id,
      :day,
      :slot,
      :start_time,
      :end_time
    ])
    |> validate_required([
      :pto_request_id,
      :accrual_policy_id,
      :pto_type_id,
      :slot
    ])
  end
end
