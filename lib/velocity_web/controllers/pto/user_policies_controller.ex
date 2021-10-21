defmodule VelocityWeb.Controllers.Pto.UserPoliciesController do
  use VelocityWeb, :controller

  alias Velocity.Contexts.Pto.AccrualPolicies
  alias Velocity.Contexts.Pto.Transactions
  alias Velocity.Contexts.Pto.UserPolicies
  alias Velocity.Contexts.Users
  alias Velocity.Repo
  alias Velocity.Utils.Dates, as: Utils
  alias VelocityWeb.Controllers.RenderHelpers

  require Logger

  def assign_user_policy(conn, params) do
    # credo:disable-for-lines:40 Credo.Check.Refactor.Nesting
    case Users.find_by_okta_user_uid(params.user.okta_user_uid) do
      {:ok, user} ->
        case UserPolicies.assign_user_policies(
               user,
               params.user.start_date,
               params.pega_policy_ids
             ) do
          {:ok, success} ->
            user_policies =
              success
              |> Enum.into([])
              |> Enum.reduce([], fn {key, value}, acc ->
                if String.contains?(key, "assign_policy") do
                  [value | acc]
                else
                  acc
                end
              end)

            Enum.each(user_policies, fn user_policy ->
              {:ok, _} =
                Transactions.accrue_between_dates(
                  user_policy,
                  Utils.parse_pega_date!(params.user.start_date),
                  Date.utc_today()
                )
            end)

            RenderHelpers.render_success(conn, success)

          {:error, error} ->
            RenderHelpers.render_error(conn, error)

          error ->
            RenderHelpers.render_error(conn, error)
        end

      error ->
        RenderHelpers.render_error(conn, error)
    end
  rescue
    error ->
      Logger.error(Exception.format(:error, error, __STACKTRACE__))
      RenderHelpers.render_success(conn, %{message: :ok})
  end

  def remove_user_policies(conn, params) do
    with {:ok, user} <- Users.find_by_okta_user_uid(params.user.okta_user_uid),
         accrual_policies when is_list(accrual_policies) <-
           AccrualPolicies.by_pega_policy_ids(params.pega_policy_ids),
         {:ok, _user_policy_multi_worked} <-
           UserPolicies.remove_user_policies(user, accrual_policies) do
      RenderHelpers.render_success(conn, %{
        user: user,
        accrual_policy_ids: Enum.map(accrual_policies, & &1.id)
      })
    else
      {:error, error} ->
        RenderHelpers.render_error(conn, error)
    end
  rescue
    error ->
      Logger.error(Exception.format(:error, error, __STACKTRACE__))

      RenderHelpers.render_success(conn, %{message: "this actually didn't work"})
  end

  def list(conn, params) do
    with {:ok, user} <- Users.find_by_okta_user_uid(params.user.okta_user_uid),
         user <- Repo.preload(user, :accrual_policies) do
      RenderHelpers.render_success(conn, %{
        user: user,
        pega_policy_ids: Enum.map(user.accrual_policies, & &1.pega_policy_id)
      })
    else
      {:error, error} ->
        RenderHelpers.render_error(conn, error)

      error ->
        RenderHelpers.render_error(conn, error)
    end
  rescue
    error ->
      Logger.error(Exception.format(:error, error, __STACKTRACE__))

      RenderHelpers.render_success(conn, %{message: "this actually didn't work"})
  end
end
