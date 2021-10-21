defmodule Velocity.Schema.TimePolicyType do
  @moduledoc "schema for time_policy type"
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.TimePolicy
  alias Velocity.Schema.TimeType

  schema "time_policy_types" do
    belongs_to :time_policy, TimePolicy
    belongs_to :time_type, TimeType

    timestamps()
  end

  @doc false
  def changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [])
    |> put_assoc(:time_policy, Map.get(attrs, :time_policy), required: true)
    |> put_assoc(:time_type, Map.get(attrs, :time_type), required: true)
  end
end
