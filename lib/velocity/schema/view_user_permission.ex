defmodule Velocity.Schema.ViewUserPermissions do
  @moduledoc "schema for role permission"
  use Ecto.Schema
  import Ecto.Changeset

  schema "view_user_permissions" do
    field :slug, :string
    field :description, :string
    field :user_id, :id

    timestamps()
  end

  @doc false
  def changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [])
    |> put_assoc(:role, Map.get(attrs, :role), required: true)
    |> put_assoc(:permission, Map.get(attrs, :permission), required: true)
  end
end
