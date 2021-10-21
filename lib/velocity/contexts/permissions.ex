defmodule Velocity.Contexts.Permissions do
  @moduledoc "context for permissions"

  alias Velocity.Repo
  alias Velocity.Schema.Group
  alias Velocity.Schema.GroupPermission
  alias Velocity.Schema.Permission
  alias Velocity.Schema.Role
  alias Velocity.Schema.RolePermission

  def create(params) do
    changeset = Permission.changeset(%Permission{}, params)

    Repo.insert(changeset)
  end

  def add_permission_to_group(permission = %Permission{}, group = %Group{}) do
    changeset =
      GroupPermission.changeset(%GroupPermission{}, %{permission: permission, group: group})

    Repo.insert(changeset)
  end

  def add_permission_to_role(permission = %Permission{}, role = %Role{}) do
    changeset = RolePermission.changeset(%RolePermission{}, %{permission: permission, role: role})

    Repo.insert(changeset)
  end
end
