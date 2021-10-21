defmodule VelocityWeb.Resolvers.Pto.UserPolicies do
  @moduledoc """
    resolver for accrual policies
  """

  alias Velocity.Contexts.Pto.UserPolicies
  alias Velocity.Contexts.Users

  def for_user(args, _) do
    user_id =
      if Map.get(args, :user_id) do
        args.user_id
      else
        user = Users.get_by(email: args.email)
        user.id
      end

    {:ok, UserPolicies.for_user(user_id)}
  end

  def deactivate_user_policy(args, _) do
    end_date =
      if Map.has_key?(args, :end_date) do
        args.end_date
      else
        NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      end

    UserPolicies.deactivate_user_policy(args.accrual_policy_id, args.user_id, end_date)
  end
end
