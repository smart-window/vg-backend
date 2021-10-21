defmodule VelocityWeb.Resolvers.Pto.Users do
  @moduledoc """
    resolver for accrual policies
  """

  alias Velocity.Repo
  alias Velocity.Schema.Pto.UserPolicy
  alias Velocity.Schema.User

  import Ecto.Query

  def with_policies(_args, _) do
    users_that_have_policies = from(u in User, join: up in UserPolicy, on: u.id == up.user_id)

    {:ok, Repo.all(users_that_have_policies)}
  end
end
