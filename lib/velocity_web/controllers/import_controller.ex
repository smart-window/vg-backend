defmodule VelocityWeb.Controllers.ImportController do
  use VelocityWeb, :controller

  alias Velocity.Contexts.EmailTemplates
  alias Velocity.Contexts.NotificationTemplates
  alias Velocity.Contexts.ProcessTemplates
  alias VelocityWeb.Controllers.RenderHelpers

  def email_templates(conn, params) do
    conn
    |> put_resp_content_type("application/json")

    try do
      case EmailTemplates.import(params[:email_templates]) do
        {:ok, email_templates} ->
          email_template_ids =
            Enum.map(email_templates, fn email_template -> email_template.id end)

          RenderHelpers.render_success(conn, %{ids: email_template_ids})

        {:error, error} ->
          RenderHelpers.render_error(conn, %{error: error})

        _ ->
          RenderHelpers.render_error(conn, %{error: "Unknown error detected"})
      end
    rescue
      x -> RenderHelpers.render_error(conn, %{error: Exception.format(:error, x, __STACKTRACE__)})
    end
  end

  def notification_templates(conn, params) do
    conn
    |> put_resp_content_type("application/json")

    try do
      case NotificationTemplates.import(params[:notification_templates]) do
        {:ok, notification_templates} ->
          notification_template_ids =
            Enum.map(notification_templates, fn notification_template ->
              notification_template.id
            end)

          RenderHelpers.render_success(conn, %{ids: notification_template_ids})

        {:error, error} ->
          RenderHelpers.render_error(conn, %{error: error})

        _ ->
          RenderHelpers.render_error(conn, %{error: "Unknown error detected"})
      end
    rescue
      x -> RenderHelpers.render_error(conn, %{error: Exception.format(:error, x, __STACKTRACE__)})
    end
  end

  def process_templates(conn, params) do
    conn
    |> put_resp_content_type("application/json")

    try do
      case ProcessTemplates.import(params[:process_templates]) do
        {:ok, process_templates} ->
          process_template_ids =
            Enum.map(process_templates, fn process_template -> process_template.id end)

          RenderHelpers.render_success(conn, %{ids: process_template_ids})

        {:error, error} ->
          RenderHelpers.render_error(conn, %{error: error})

        _ ->
          RenderHelpers.render_error(conn, %{error: "Unknown error detected"})
      end
    rescue
      x -> RenderHelpers.render_error(conn, %{error: Exception.format(:error, x, __STACKTRACE__)})
    end
  end
end
