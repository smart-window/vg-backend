defmodule Velocity.Schema.ClientSentEmail do
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Client
  alias Velocity.Schema.SentEmail

  schema "client_sent_emails" do
    belongs_to :client, Client
    belongs_to :sent_email, SentEmail

    timestamps()
  end

  @doc false
  def changeset(client_sent_email, attrs) do
    client_sent_email
    |> cast(attrs, [:client_id, :sent_email_id])
    |> validate_required([:client_id, :sent_email_id])
  end
end
