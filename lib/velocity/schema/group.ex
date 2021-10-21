defmodule Velocity.Schema.Group do
  @moduledoc "schema for group"
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.GroupPermission

  schema "groups" do
    field :slug, :string
    field :description, :string
    field :okta_group_slug, :string
    field :is_super_admin, :boolean
    has_many :group_permissions, GroupPermission
    has_many :permissions, through: [:group_permissions, :permission]

    timestamps()
  end

  @doc false
  def changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [:slug, :description, :okta_group_slug, :is_super_admin])
    |> validate_required([:slug, :okta_group_slug])
  end
end
