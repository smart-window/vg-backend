defmodule Velocity.Schema.TimeEntry do
  @moduledoc "schema for time_entry"
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Employment
  alias Velocity.Schema.TimePolicy
  alias Velocity.Schema.TimeType
  alias Velocity.Schema.User
  alias Velocity.Utils.Changesets, as: Utils

  @fields [
    :description,
    :user_id,
    :time_type_id,
    :time_policy_id,
    :employment_id,
    :event_date,
    :total_hours
  ]

  @required_fields [
    :event_date,
    :total_hours
  ]

  schema "time_entries" do
    field :event_date, :date
    field :description, :string
    field :total_hours, :float
    field :metadata, :map

    belongs_to :time_type, TimeType
    belongs_to :time_policy, TimePolicy
    belongs_to :user, User
    belongs_to :employment, Employment

    timestamps()
  end

  @doc false
  def changeset(changeset, attrs) do
    changeset
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> Utils.maybe_put_assoc(:time_type, attrs)
  end
end
