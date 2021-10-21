defmodule Velocity.Schema.ClientDocument do
  @moduledoc "schema for client document"
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Client
  alias Velocity.Schema.Document

  schema "client_documents" do
    belongs_to :client, Client
    belongs_to :document, Document

    timestamps()
  end

  @doc false
  def changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [])
    |> put_assoc(:client, Map.get(attrs, :client), required: true)
    |> put_assoc(:document, Map.get(attrs, :document), required: true)
  end
end
