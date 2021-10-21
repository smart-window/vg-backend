defmodule VelocityWeb.Resolvers.Roles do
  @moduledoc """
  GQL resolver for roles
  """
  alias Velocity.Contexts.Roles

  def csr_roles(_args, _) do
    {:ok, Roles.csr_roles()}
  end

  def client_manager_roles(_args, _) do
    {:ok, Roles.client_manager_roles()}
  end
end
