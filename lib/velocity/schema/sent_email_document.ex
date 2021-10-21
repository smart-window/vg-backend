defmodule Velocity.Schema.SentEmailDocument do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sent_email_documents" do
    belongs_to :sent_email, Velocity.Schema.SentEmail
    belongs_to :document, Velocity.Schema.Document

    timestamps()
  end

  @doc false
  def changeset(sent_email_document, attrs) do
    sent_email_document
    |> cast(attrs, [
      :sent_email_id,
      :document_id
    ])
    |> validate_required([
      :sent_email_id,
      :document_id
    ])
  end
end
