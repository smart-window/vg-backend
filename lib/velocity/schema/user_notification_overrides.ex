defmodule Velocity.Schema.UserNotificationOverride do
  @moduledoc """
    schema for user notification overrides

    a user notification override occurs when a user wants to modify the default notification behaivour
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Velocity.Schema.NotificationDefault
  alias Velocity.Schema.User

  @fields [:should_send]
  @required_fields [:should_send]

  schema "user_notification_overrides" do
    field :should_send, :boolean

    belongs_to :notification_default, NotificationDefault
    belongs_to :user, User

    timestamps()
  end

  def changeset(changeset, attrs) do
    changeset
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
  end
end
