defmodule VelocityWeb.Resolvers.CsrUsers do
  @moduledoc """
    resolver for csr users
  """

  alias Velocity.Contexts.Users

  def csr_users(_args, _) do
    {:ok, Users.csr_users()}
  end
end
