defmodule Velocity.Schema.NotificationTemplate do
  @moduledoc """
    schema for notification templates

    a notification template is associated to an event and contains the content of the notification
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Velocity.Event
  alias Velocity.Schema.EmailTemplate

  @fields [:event, :title, :body, :image_url]
  @required_fields [:event, :body]

  @derive {Jason.Encoder, only: @fields ++ [:id]}

  schema "notification_templates" do
    field :event, :string
    field :title, :string
    field :body, :string
    field :image_url, :string

    belongs_to :email_template, EmailTemplate

    timestamps()
  end

  def changeset(changeset, attrs) do
    changeset
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:event, Event.events())
  end
end
