defmodule Velocity.Schema.TimePolicy do
  @moduledoc "schema for time_policy"
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.TimePolicyType

  schema "time_policies" do
    field :slug, :string
    field :work_week_start, :integer
    field :work_week_end, :integer
    has_many :time_policy_types, TimePolicyType
    has_many :time_types, through: [:time_policy_types, :time_type]

    timestamps()
  end

  @doc false
  def changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [:slug, :work_week_start, :work_week_end])
    |> validate_required([:slug, :work_week_start, :work_week_end])
    |> validate_inclusion(:work_week_start, 0..6)
    |> validate_inclusion(:work_week_end, 0..6)
  end
end
