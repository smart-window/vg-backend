defmodule Velocity.Schema.GroupPermission do
  @moduledoc "schema for group permission"
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Group
  alias Velocity.Schema.Permission

  schema "group_permissions" do
    belongs_to :group, Group
    belongs_to :permission, Permission

    timestamps()
  end

  @doc false
  def changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [])
    |> put_assoc(:group, Map.get(attrs, :group), required: true)
    |> put_assoc(:permission, Map.get(attrs, :permission), required: true)
  end
end
