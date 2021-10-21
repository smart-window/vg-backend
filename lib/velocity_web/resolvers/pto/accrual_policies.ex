defmodule VelocityWeb.Resolvers.Pto.AccrualPolicies do
  @moduledoc """
    resolver for accrual policies
  """

  alias Velocity.Contexts.Pto.AccrualPolicies
  alias Velocity.Repo

  def all(_args, _) do
    {:ok, AccrualPolicies.all()}
  end

  def accrual_policies_report(args, _) do
    accrual_policy_report_items =
      AccrualPolicies.accrual_policies_report(
        args.page_size,
        String.to_atom(Macro.underscore(args.sort_column)),
        String.to_atom(args.sort_direction),
        args.last_id,
        args.last_value,
        args.filter_by,
        args.search_by
      )

    row_count =
      if Enum.count(accrual_policy_report_items) > 0 do
        Enum.at(accrual_policy_report_items, 0)[:sql_row_count]
      else
        0
      end

    {:ok, %{row_count: row_count, accrual_policy_report_items: accrual_policy_report_items}}
  end

  def get(args, _) do
    accrual_policy =
      AccrualPolicies.get_by(id: args.accrual_policy_id)
      |> Repo.preload(:levels)

    {:ok, accrual_policy}
  end

  def create_accrual_policy(args, _) do
    AccrualPolicies.create_accrual_policy(args)
  end

  def update_accrual_policy(args, _) do
    AccrualPolicies.update_accrual_policy(args.id, Map.delete(args, :id))
  end

  def delete_accrual_policy(args, _) do
    AccrualPolicies.delete_accrual_policy(args)
  end
end
