defmodule VelocityWeb.Controllers.Pto.LedgersController do
  use VelocityWeb, :controller

  alias Velocity.Contexts.Pto.AccrualPolicies
  alias Velocity.Contexts.Pto.Ledgers
  alias Velocity.Contexts.Users
  alias Velocity.Repo
  alias VelocityWeb.Controllers.RenderHelpers

  require Logger

  def by_user(conn, params) do
    with {:ok, user} <- Users.find_by_okta_user_uid(params.okta_user_uid),
         accrual_policies <- AccrualPolicies.by_user_id(user.id) do
      information =
        accrual_policies
        |> Enum.filter(fn policy ->
          !Map.has_key?(params, :pega_policy_id) || params.pega_policy_id == policy.pega_policy_id
        end)
        |> Enum.map(fn policy ->
          last_ledger = Ledgers.last_ledger_entry(user, policy) || %{}

          %{
            okta_user_uid: user.okta_user_uid,
            pega_policy_id: policy.pega_policy_id,
            regular_balance: Map.get(last_ledger, :regular_balance),
            carryover_balance: Map.get(last_ledger, :carryover_balance),
            pto_taken: abs(Ledgers.days_taken(user, policy))
          }
        end)

      RenderHelpers.render_success(conn, %{accrual_policies: information})
    else
      error -> RenderHelpers.render_error(conn, error)
    end
  end

  def delete_all(conn, params) do
    Ledgers.delete_ledgers(params.user_id, params.policy_id)

    RenderHelpers.render_success(conn, %{message: :deleted})
  end

  def list(conn, params) do
    with {:ok, user} <- Users.find_by_okta_user_uid(params.okta_user_uid),
         {:ok, accrual_policy} <-
           AccrualPolicies.find_by_pega_policy_id(params.pega_policy_id) do
      %{ledgers: ledgers, last_ledger: last_ledger, accrual_policy: accrual_policy} =
        Ledgers.list(user, accrual_policy)

      RenderHelpers.render_success(conn, %{
        transactions: ledgers,
        accrual_policy: accrual_policy,
        regular_balance: last_ledger.regular_balance,
        carryover_balance: last_ledger.carryover_balance
      })
    else
      error -> RenderHelpers.render_error(conn, error)
    end
  rescue
    error ->
      Logger.error(Exception.format(:error, error, __STACKTRACE__))

      RenderHelpers.render_success(conn, %{message: "this actually didn't work"})
  end

  def export_all(conn, _) do
    user = Users.get_by(okta_user_uid: conn.assigns[:current_user_okta_uid])
    user_with_permissions = user |> Repo.preload(:permissions)

    if Enum.find(user_with_permissions.permissions, fn permission ->
         permission.slug == "pto"
       end) do
      file = Ledgers.export_all_to_csv()

      send_file(conn, 200, file.path)
    else
      RenderHelpers.render_error(conn, %{message: :unauthorized})
    end
  rescue
    error ->
      Logger.error(Exception.format(:error, error, __STACKTRACE__))

      RenderHelpers.render_success(conn, %{message: "this actually didn't work"})
  end
end
