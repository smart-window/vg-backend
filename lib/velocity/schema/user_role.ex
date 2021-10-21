defmodule Velocity.Schema.UserRole do
  @moduledoc "schema for user role"
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Role
  alias Velocity.Schema.User

  schema "user_roles" do
    belongs_to :role, Role
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [])
    |> put_assoc(:role, Map.get(attrs, :role), required: true)
    |> put_assoc(:user, Map.get(attrs, :user), required: true)
  end
end
