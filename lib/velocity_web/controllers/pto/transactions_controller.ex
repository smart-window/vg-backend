defmodule VelocityWeb.Controllers.Pto.TransactionsController do
  use VelocityWeb, :controller

  alias Velocity.Contexts.Employments
  alias Velocity.Contexts.Pto.AccrualPolicies
  alias Velocity.Contexts.Pto.Ledgers
  alias Velocity.Contexts.Pto.Transactions
  alias Velocity.Contexts.Users
  alias VelocityWeb.Controllers.RenderHelpers

  require Logger

  def nightly_accrual(conn, params) do
    with {:ok, user} <- Users.find_by_okta_user_uid(params.user.okta_user_uid),
         {:ok, accrual_policy} <-
           AccrualPolicies.find_by_pega_policy_id(params.accrual_policy.pega_policy_id) do
      employment = Employments.get_for_user(user.id)

      case Transactions.nightly_accrual(
             user,
             employment,
             accrual_policy
           ) do
        {:ok, nil} ->
          RenderHelpers.render_success(conn, %{message: "nothing to accrue"})

        {:ok, ledger} ->
          RenderHelpers.render_success(conn, ledger)

        {:error, error} ->
          RenderHelpers.render_error(conn, error)
      end
    else
      error -> RenderHelpers.render_error(conn, error)
    end
  rescue
    error ->
      Logger.error(Exception.format(:error, error, __STACKTRACE__))

      RenderHelpers.render_success(conn, %{message: "this actually didn't work"})
  end

  def taken(conn, params) do
    with {:ok, user} <- Users.find_by_okta_user_uid(params.user.okta_user_uid),
         {:ok, accrual_policy} <-
           AccrualPolicies.find_by_pega_policy_id(params.accrual_policy.pega_policy_id) do
      employment = Employments.get_for_user(user.id)

      case Transactions.taken(
             %{
               amount: params.amount,
               notes: Map.get(params, :adjustment_notes),
               employment: employment
             },
             user,
             accrual_policy
           ) do
        {:ok, ledger} ->
          RenderHelpers.render_success(conn, ledger)

        {:error, error} ->
          RenderHelpers.render_error(conn, error)
      end
    else
      error -> RenderHelpers.render_error(conn, error)
    end
  rescue
    error ->
      Logger.error(Exception.format(:error, error, __STACKTRACE__))

      RenderHelpers.render_success(conn, %{message: "this actually didn't work"})
  end

  def withdrawn(conn, params) do
    with {:ok, user} <- Users.find_by_okta_user_uid(params.user.okta_user_uid),
         {:ok, accrual_policy} <-
           AccrualPolicies.find_by_pega_policy_id(params.accrual_policy.pega_policy_id) do
      ledger = Ledgers.get_by(id: Map.get(params, :ledger_id))
      regular_amount = -ledger.regular_transaction
      carryover_amount = -ledger.carryover_transaction

      case Transactions.withdrawn(
             regular_amount,
             carryover_amount,
             Map.get(params, :adjustment_notes),
             user,
             accrual_policy
           ) do
        {:ok, ledger} ->
          RenderHelpers.render_success(conn, ledger)

        {:error, error} ->
          RenderHelpers.render_error(conn, error)
      end
    else
      error -> RenderHelpers.render_error(conn, error)
    end
  rescue
    error ->
      Logger.error(Exception.format(:error, error, __STACKTRACE__))

      RenderHelpers.render_success(conn, %{message: "this actually didn't work"})
  end

  def manual_adjustment(conn, params) do
    with {:ok, user} <- Users.find_by_okta_user_uid(params.user.okta_user_uid),
         {:ok, accrual_policy} <-
           AccrualPolicies.find_by_pega_policy_id(params.accrual_policy.pega_policy_id) do
      case Transactions.manual_adjustment(
             params.amount,
             user,
             accrual_policy,
             Map.get(params, :adjustment_notes)
           ) do
        {:ok, ledger} ->
          RenderHelpers.render_success(conn, ledger)

        {:error, error} ->
          RenderHelpers.render_error(conn, error)
      end
    else
      error -> RenderHelpers.render_error(conn, error)
    end
  rescue
    error ->
      Logger.error(Exception.format(:error, error, __STACKTRACE__))

      RenderHelpers.render_success(conn, %{message: "this actually didn't work"})
  end
end
