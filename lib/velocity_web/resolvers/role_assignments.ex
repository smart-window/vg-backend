defmodule VelocityWeb.Resolvers.RoleAssignments do
  @moduledoc """
  GQL resolver for role assignments
  """
  alias Velocity.Contexts.RoleAssignments
  alias Velocity.Repo

  def for_current_user(_args, %{context: %{current_user: current_user}}) do
    user_with_role_assignments = current_user |> Repo.preload([:role_assignments])

    {:ok, user_with_role_assignments.role_assignments}
  end

  def update_client_manager_role(args, _) do
    RoleAssignments.update_client_manager_role(args)
  end
end
