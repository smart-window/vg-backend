defmodule Velocity.Schema.RoleAssignment do
  @moduledoc "schema for role_assignment"
  use Ecto.Schema
  import Ecto.Changeset
  alias Velocity.Schema.Client
  alias Velocity.Schema.Country
  alias Velocity.Schema.Role
  alias Velocity.Schema.User

  schema "role_assignments" do
    field :assignment_type, :string
    belongs_to :user, User
    belongs_to :role, Role
    belongs_to :employee, User
    belongs_to :country, Country
    belongs_to :client, Client

    timestamps()
  end

  @doc false
  def changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [:client_id, :user_id, :role_id, :employee_id])
  end
end
