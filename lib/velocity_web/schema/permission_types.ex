defmodule VelocityWeb.Schema.PermissionTypes do
  @moduledoc false
  use Absinthe.Schema.Notation

  alias Velocity.Repo
  alias Velocity.Schema.Role

  @desc "permission"
  object :permission do
    field :id, :id
    field :slug, :string
  end

  @desc "role_assignment"
  object :role_assignment do
    field :id, :id
    field :user_id, :id
    field :role_id, :id
    field :employee_id, :id
    field :country_id, :id
    field :client_id, :id
    field :assignment_type, :string

    field(:role, :role) do
      resolve(fn role_assignment, _args, _info ->
        role = Repo.get_by(Role, id: role_assignment.role_id)
        {:ok, role}
      end)
    end
  end
end
