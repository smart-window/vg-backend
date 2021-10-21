defmodule VelocityWeb.Resolvers.Pto.Ledgers do
  @moduledoc """
    resolver for accrual policies
  """

  alias Velocity.Contexts.Pto.Ledgers
  alias Velocity.Repo
  alias Velocity.Schema.Pto.AccrualPolicy
  alias Velocity.Schema.User

  def list(args, _) do
    {:ok, Ledgers.list(args.user_id, args.accrual_policy_id)}
  end

  def last_ledger_entry(args, _) do
    user = Repo.get!(User, args.user_id)
    accrual_policy = Repo.get!(AccrualPolicy, args.accrual_policy_id)
    {:ok, Ledgers.last_ledger_entry(user, accrual_policy, nil)}
  end
end
