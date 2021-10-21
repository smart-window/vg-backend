defmodule Velocity.Contexts.RoleAssignments do
  @moduledoc "context for role_assignments"

  alias Velocity.Contexts.Roles
  alias Velocity.Repo
  alias Velocity.Schema.ClientManager
  alias Velocity.Schema.Employment
  alias Velocity.Schema.RoleAssignment

  import Ecto.Query

  def create(params) do
    changeset = RoleAssignment.changeset(%RoleAssignment{}, params)

    Repo.insert(changeset)
  end

  def get_assignment_type(user, role_slug) do
    user_is_admin = Repo.preload(user, [:groups]).groups |> Enum.any?(&(&1.slug == "admin"))

    role = Roles.get_by(slug: role_slug)
    role_assignment = Repo.get_by(RoleAssignment, %{user_id: user.id, role_id: role.id})

    role_assignment_type =
      if is_nil(role_assignment), do: nil, else: role_assignment.assignment_type

    if user_is_admin do
      "global"
    else
      role_assignment_type
    end
  end

  def update_client_manager_role(args) do
    employment = Repo.get_by(Employment, %{id: args.employment_id})
    client_manager = Repo.get_by(ClientManager, %{id: args.id})

    if args.active do
      %RoleAssignment{}
      |> RoleAssignment.changeset(%{
        user_id: client_manager.user_id,
        role_id: args.role_id,
        client_id: client_manager.client_id,
        employee_id: employment.employee_id
      })
      |> Repo.insert()
    else
      role_assignment =
        Repo.one!(
          from(ra in RoleAssignment,
            where:
              ra.user_id == ^client_manager.user_id and ra.client_id == ^client_manager.client_id and
                ra.role_id == ^args.role_id and ra.employee_id == ^employment.employee_id
          )
        )

      Repo.delete(role_assignment)
    end
  end
end
