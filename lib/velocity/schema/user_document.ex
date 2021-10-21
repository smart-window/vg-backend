defmodule Velocity.Schema.UserDocument do
  @moduledoc "schema for user document"
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Document
  alias Velocity.Schema.User

  schema "user_documents" do
    belongs_to :user, User
    belongs_to :document, Document

    timestamps()
  end

  @doc false
  def changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [])
    |> put_assoc(:user, Map.get(attrs, :user), required: true)
    |> put_assoc(:document, Map.get(attrs, :document), required: true)
  end
end
