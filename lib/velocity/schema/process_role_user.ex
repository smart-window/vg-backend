defmodule Velocity.Schema.ProcessRoleUser do
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Process
  alias Velocity.Schema.Role
  alias Velocity.Schema.User

  schema "process_role_users" do
    belongs_to :process, Process
    belongs_to :role, Role
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(process_role_user, attrs) do
    process_role_user
    |> cast(attrs, [:process_id, :role_id, :user_id])
    |> validate_required([])
  end
end
