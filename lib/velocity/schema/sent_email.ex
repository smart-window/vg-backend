defmodule Velocity.Schema.SentEmail do
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.SentEmailUser

  schema "sent_emails" do
    field :body, :string
    field :description, :string
    field :sent_date, :naive_datetime
    field :subject, :string

    has_many :sent_email_users, SentEmailUser
    has_many :users, through: [:sent_email_users, :user]

    timestamps()
  end

  @doc false
  def changeset(sent_email, attrs) do
    sent_email
    |> cast(attrs, [:description, :subject, :body, :sent_date])
    |> validate_required([:description, :subject, :body, :sent_date])
  end
end
