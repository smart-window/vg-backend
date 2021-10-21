defmodule Velocity.Schema.RolePermission do
  @moduledoc "schema for role permission"
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Permission
  alias Velocity.Schema.Role

  schema "role_permissions" do
    belongs_to :role, Role
    belongs_to :permission, Permission

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
