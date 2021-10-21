defmodule Velocity.Schema.NotificationDefault do
  @moduledoc """
    schema for notification defaults

    a notification default belongs to an event and indicates which channel the notification will be delivered on

    the roles array allows the notification to be sent to an applicable role
    the actors array allows the notification to be sent to an applicable actor
    the user_ids array allows the notification to be sent to specific users
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Velocity.Schema.NotificationTemplate

  @fields [:channel, :minutes_from_event, :roles, :actors, :user_ids]
  @required_fields [:channel, :minutes_from_events]

  schema "notification_defaults" do
    field :channel, :string
    field :minutes_from_event, :integer
    field :roles, {:array, :string}
    field :actors, {:array, :string}
    field :user_ids, {:array, :integer}

    belongs_to :notification_template, NotificationTemplate

    timestamps()
  end

  def changeset(changeset, attrs) do
    changeset
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:channel, ["desktop", "mobile", "email"])
  end
end
