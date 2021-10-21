defmodule Velocity.Schema.Role do
  @moduledoc "schema for role"
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.RolePermission

  schema "roles" do
    field :slug, :string
    field :description, :string
    has_many :role_permissions, RolePermission
    has_many :permissions, through: [:role_permissions, :permission]

    timestamps()
  end

  @doc false
  def changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [:slug, :description])
    |> validate_required([:slug])
  end
end
