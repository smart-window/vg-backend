defmodule Velocity.Schema.SentEmailUser do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sent_email_users" do
    field :email_address, :string
    field :recipient_type, :string
    belongs_to :sent_email, Velocity.Schema.SentEmail
    belongs_to :user, Velocity.Schema.User

    timestamps()
  end

  @doc false
  def changeset(sent_email_user, attrs) do
    sent_email_user
    |> cast(attrs, [
      :sent_email_id,
      :user_id,
      :email_address,
      :recipient_type
    ])
    |> validate_required([
      :sent_email_id,
      :email_address,
      :recipient_type
    ])
  end
end
