defmodule Velocity.Schema.Contract do
  @moduledoc "
    schema for contract
    represents the terms under which an employee is employed to a job
  "
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Client

  schema "contracts" do
    field :uuid, :string
    field :payroll_13th_month, USMonthEnumEnum
    field :payroll_14th_month, USMonthEnumEnum
    field :termination_date, :date
    field :termination_reason, :string
    field :termination_sub_reason, :string

    belongs_to :client, Client

    timestamps()
  end

  @doc false
  def changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [
      :client_id,
      :uuid,
      :payroll_13th_month,
      :payroll_14th_month,
      :termination_date,
      :termination_reason,
      :termination_sub_reason
    ])
    |> validate_required([
      :client_id
    ])
  end
end
