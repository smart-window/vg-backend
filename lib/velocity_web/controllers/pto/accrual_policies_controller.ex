defmodule VelocityWeb.Controllers.Pto.AccrualPoliciesController do
  use VelocityWeb, :controller

  alias Velocity.Contexts.Pto.AccrualPolicies
  alias Velocity.Contexts.Pto.Levels
  alias VelocityWeb.Controllers.RenderHelpers

  require Logger

  def create(conn, params) do
    case AccrualPolicies.create(
           params.accrual_policy,
           on_conflict: :nothing,
           conflict_target: :pega_level_id
         ) do
      {:ok, good} ->
        RenderHelpers.render_success(conn, good)

      {:error, bad} ->
        RenderHelpers.render_error(conn, bad)
    end
  rescue
    error ->
      Logger.error(Exception.format(:error, error, __STACKTRACE__))

      RenderHelpers.render_success(conn, %{message: "this actually didn't work"})
  end

  def all(conn, _params) do
    policies = AccrualPolicies.all()

    RenderHelpers.render_success(conn, %{policies: policies})
  rescue
    error ->
      Logger.error(Exception.format(:error, error, __STACKTRACE__))

      RenderHelpers.render_success(conn, %{message: "this actually didn't work"})
  end

  def delete(conn, params) do
    AccrualPolicies.delete(params.pega_policy_id)

    RenderHelpers.render_success(conn, %{message: "policy removed"})
  rescue
    error ->
      Logger.error(Exception.format(:error, error, __STACKTRACE__))

      RenderHelpers.render_success(conn, %{message: "this actually didn't work"})
  end

  def delete_level(conn, params) do
    Levels.delete(params.pega_level_id)

    RenderHelpers.render_success(conn, %{message: "level removed"})
  rescue
    error ->
      Logger.error(Exception.format(:error, error, __STACKTRACE__))

      RenderHelpers.render_success(conn, %{message: "this actually didn't work"})
  end

  def update(conn, params) do
    case AccrualPolicies.update(params) do
      {:ok, policy} ->
        RenderHelpers.render_success(conn, policy)

      {:error, error} ->
        RenderHelpers.render_error(conn, error)
    end
  rescue
    error ->
      Logger.error(Exception.format(:error, error, __STACKTRACE__))

      RenderHelpers.render_success(conn, %{message: "this actually didn't work"})
  end

  def get(conn, params) do
    policy = AccrualPolicies.get_by(pega_policy_id: params.pega_policy_id)

    RenderHelpers.render_success(conn, policy)
  rescue
    error ->
      Logger.error(Exception.format(:error, error, __STACKTRACE__))

      RenderHelpers.render_success(conn, %{message: "this actually didn't work"})
  end
end
