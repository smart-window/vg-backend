defmodule VelocityWeb.Controllers.OktaController do
  use VelocityWeb, :controller

  require Logger

  alias Velocity.Contexts.Groups
  alias Velocity.Contexts.Users
  alias Velocity.Repo
  alias Velocity.Schema.UserGroup

  # credo:disable-for-lines:40 Credo.Check.Refactor.CyclomaticComplexity
  def user_check(conn, params) do
    Logger.info("checking user #{inspect(redact(params))}")

    username = Map.get(params, :username)

    message =
      "If #{username} has an account with Velocity Global, you will receive an email with instructions for recovering your account"

    case okta_client().get_user(username) do
      {:ok, %{body: %{"errorCode" => "E0000007"}}} ->
        conn
        |> put_status(200)
        |> json(%{message: message})

      {:ok, %{status: 200, body: %{"id" => id, "status" => status}}}
      when status in ["ACTIVE", "RECOVERY", "PASSWORD EXPIRED"] ->
        # send password reset email
        Logger.info("attempting to reset. status #{status}")

        case okta_client().reset_password(id) do
          {:ok, %{status: 200}} ->
            conn
            |> put_status(200)
            |> json(%{
              message: message
            })
        end

      {:ok, %{status: 200, body: %{"id" => id, "status" => status}}}
      when status in ["PROVISIONED"] ->
        # reactivate
        case okta_client().reactivate(id) do
          {:ok, %{status: 200}} ->
            conn
            |> put_status(200)
            |> json(%{message: message})
        end

      {:ok, %{status: 200, body: %{"id" => id, "status" => status}}}
      when status in ["STAGED"] ->
        # resend activation email
        case okta_client().activate(id) do
          {:ok, %{status: 200}} ->
            conn
            |> put_status(200)
            |> json(%{message: message})
        end

      {:ok, %{status: 200, body: body}} ->
        Logger.error("okta user unhandled_status #{inspect(body)}")

        conn
        |> put_status(200)
        |> json(%{message: message})

      {:ok, body = %{status: status}} when status > 299 ->
        Logger.error("okta user check error #{inspect(body)}")

        conn
        |> put_status(400)
        |> json(%{message: "something went wrong."})

      error ->
        Logger.error("okta user check error #{inspect(error)}")

        conn
        |> put_status(400)
        |> json(%{message: "something went wrong."})
    end
  end

  # General entry point
  def received(conn, params) do
    Logger.info("event(s) received from okta: #{inspect(redact(params))}")

    event =
      find(params["data"]["events"], "eventType", "user.lifecycle.create") ||
        find(params["data"]["events"], "eventType", "user.lifecycle.delete.initiated") ||
        find(params["data"]["events"], "eventType", "group.user_membership.add") ||
        find(params["data"]["events"], "eventType", "group.user_membership.remove")

    if event do
      process_event(event, conn)
    else
      Logger.error("could not find event for payload: #{inspect(redact(params))}")

      conn
      |> put_status(422)
      |> json(%{})
    end
  end

  def process_event(event = %{"eventType" => "user.lifecycle.create"}, conn) do
    Logger.info("user.lifecycle.create event received from okta")
    user_params = find(event["target"], "type", "User")

    case find_or_create_user_from_event(user_params) do
      {:ok, user} ->
        user_group_params = filter(event["target"], "type", "UserGroup")
        add_user_to_groups_and_roles(user, user_group_params)

        conn
        |> put_status(200)
        |> json(%{})

      {:error, error} ->
        Logger.error("error creating user #{inspect(error)}")

        conn
        |> put_status(422)
        |> json(%{})
    end
  end

  def process_event(event = %{"eventType" => "user.lifecycle.delete.initiated"}, conn) do
    Logger.info("user.lifecycle.delete.initiated event received from okta")
    user_params = find(event["target"], "type", "User")

    okta_user_uid = user_params["id"]
    Logger.info("deleting user #{okta_user_uid}")

    case Users.delete(okta_user_uid: okta_user_uid) do
      {:ok, _} ->
        conn
        |> put_status(200)
        |> json(%{})

      {:error, error} ->
        Logger.error("error deleting user #{inspect(error)}")

        conn
        |> put_status(422)
        |> json(%{})
    end
  end

  def process_event(event = %{"eventType" => "group.user_membership.add"}, conn) do
    Logger.info("group.user_membership.add event received from okta")
    user_params = find(event["target"], "type", "User")
    user_group_params = filter(event["target"], "type", "UserGroup")

    {:ok, user} = find_or_create_user_from_event(user_params)
    add_user_to_groups_and_roles(user, user_group_params)

    conn
    |> put_status(200)
    |> json(%{})
  end

  def process_event(event = %{"eventType" => "group.user_membership.remove"}, conn) do
    Logger.info("group.user_membership.remove event received from okta")
    user_params = find(event["target"], "type", "User")
    group_params = find(event["target"], "type", "UserGroup")

    user = Users.get_by(okta_user_uid: user_params["id"])
    group = Groups.get_by(okta_group_slug: group_params["displayName"])

    if user && group do
      Logger.info("removing group #{group.okta_group_slug} from user #{user.okta_user_uid}")

      case Users.remove_user_from_group(user, group) do
        {:ok, _} ->
          conn
          |> put_status(200)
          |> json(%{})

        {:error, error} ->
          Logger.error("error removing user from group #{inspect(error)}")

          conn
          |> put_status(422)
          |> json(%{})
      end
    else
      Logger.error("could not find group and group for event #{inspect(event)}")

      conn
      |> put_status(200)
      |> json(%{})
    end
  end

  def verify(conn, _params) do
    verification_value = List.first(get_req_header(conn, "x-okta-verification-challenge"))

    conn
    |> put_status(200)
    |> json(%{verification: verification_value})
  end

  def find_or_create_user_from_event(user_params) do
    okta_user_uid = user_params["id"]
    email = user_params["alternateId"]
    full_name = user_params["displayName"]
    split = String.split(full_name, " ")
    first_name = List.first(split)
    last_name = List.last(split)
    Logger.info("finding or creating user with okta_user_uid #{okta_user_uid}")

    Users.find_or_create(
      %{
        okta_user_uid: okta_user_uid,
        email: email,
        full_name: full_name,
        first_name: first_name,
        last_name: last_name
      },
      on_conflict: [set: [updated_at: DateTime.utc_now()]],
      conflict_target: [:okta_user_uid],
      returning: true
    )
  end

  def add_user_to_groups_and_roles(user, user_group_params) do
    Enum.each(user_group_params, fn user_group ->
      # credo:disable-for-lines:4 Credo.Check.Refactor.Nesting
      case Groups.get_by(okta_group_slug: user_group["displayName"]) do
        nil ->
          Logger.info("matching group not found #{inspect(user_group)}")

        group ->
          Logger.info("adding group #{inspect(user_group)} to user #{user.okta_user_uid}")
          inserted_and_updated_at = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

          user_groups_params = [
            %{
              user_id: user.id,
              group_id: group.id,
              inserted_at: inserted_and_updated_at,
              updated_at: inserted_and_updated_at
            }
          ]

          Repo.insert_all(UserGroup, user_groups_params,
            on_conflict: :nothing,
            conflict_target: [:user_id, :group_id]
          )

          Users.assign_user_roles_for_group(user, group)
      end
    end)
  end

  defp find(list, key, value) do
    Enum.find(list, &(&1[key] == value))
  end

  def filter(list, key, value) do
    Enum.filter(list, &(&1[key] == value))
  end

  defp redact(params) do
    Enum.reduce(params["data"]["events"] || [], [], fn event, acc ->
      [
        %{
          okta_request_id: get_in(event, ["debugContext", "debugData", "requestId"]),
          okta_target_uid: get_in(Enum.at(get_in(event, ["target"]) || [], 0, %{}), ["id"]),
          okta_event_timestamp: get_in(event, ["published"]),
          okta_event_type: get_in(event, ["eventType"])
        }
        | acc
      ]
    end)
  end

  defp okta_client, do: Application.get_env(:velocity, :okta_client, Velocity.Clients.Okta)
end
