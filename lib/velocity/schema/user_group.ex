defmodule Velocity.Schema.UserGroup do
  @moduledoc "schema for user group"
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Group
  alias Velocity.Schema.User

  schema "user_groups" do
    belongs_to :group, Group
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [])
    |> put_assoc(:group, Map.get(attrs, :group), required: true)
    |> put_assoc(:user, Map.get(attrs, :user), required: true)
  end
end
