defmodule Velocity.Contexts.Okta do
  @moduledoc false
  require Logger

  alias Velocity.Contexts.Groups
  alias Velocity.Contexts.Users
  alias Velocity.Repo
  alias Velocity.Schema.Group
  alias Velocity.Schema.User
  alias Velocity.Schema.UserGroup

  def sync_okta_users do
    Logger.info("okta users sync - starting")

    process_batch("")
  end

  def create_user_from_uid(nil), do: {:error, "user not found for nil id"}

  def create_user_from_uid(okta_user_uid) do
    case okta_client().get_user(okta_user_uid) do
      {:ok, okta_user} ->
        {:ok, user} =
          Users.find_or_create(
            first_name: okta_user["profile"]["firstName"],
            last_name: okta_user["profile"]["lastName"],
            full_name: "#{okta_user["profile"]["firstName"]} #{okta_user["profile"]["lastName"]}",
            email: okta_user["profile"]["email"],
            okta_user_uid: okta_user["id"]
          )

        {:ok, response} = user_groups_or_sleep(user.okta_user_uid)

        user_groups = response.body

        user_groups_params = get_user_groups_params(user_groups, user)

        Repo.insert_all(UserGroup, user_groups_params,
          on_conflict: :nothing,
          conflict_target: [:user_id, :group_id]
        )

        # Add roles corresponding to group
        Enum.each(user_groups_params, fn user_group ->
          group = Repo.get(Group, user_group.group_id)
          Users.assign_user_roles_for_group(user, group)
        end)

        {:ok, Repo.preload(user, :permissions)}
    end
  end

  defp process_batch(nil) do
    Logger.info("okta users sync - done")
  end

  defp process_batch(cursor) do
    Logger.info("okta users sync - batch starting cursor: #{cursor}")
    {:ok, response} = list_active_users_or_sleep(cursor)

    next = find_next(response.headers)
    okta_users = response.body

    inserted_and_updated_at = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    users_params =
      Enum.map(okta_users, fn okta_user ->
        %{
          first_name: okta_user["profile"]["firstName"],
          last_name: okta_user["profile"]["lastName"],
          full_name: "#{okta_user["profile"]["firstName"]} #{okta_user["profile"]["lastName"]}",
          email: okta_user["profile"]["email"],
          okta_user_uid: okta_user["id"],
          inserted_at: inserted_and_updated_at,
          updated_at: inserted_and_updated_at
        }
      end)

    {_num, users} =
      Repo.insert_all(User, users_params,
        on_conflict: [set: [updated_at: inserted_and_updated_at]],
        conflict_target: :okta_user_uid,
        returning: [:id, :okta_user_uid]
      )

    user_groups_params =
      Enum.reduce(users, [], fn user, acc ->
        {:ok, response} = user_groups_or_sleep(user.okta_user_uid)

        user_groups = response.body

        user_groups = get_user_groups_params(user_groups, user)
        acc ++ user_groups
      end)

    Repo.insert_all(UserGroup, user_groups_params,
      on_conflict: :nothing,
      conflict_target: [:user_id, :group_id]
    )

    # Add roles corresponding to group
    Enum.each(user_groups_params, fn user_group ->
      user = Enum.find(users, &(&1.id == user_group.user_id))
      group = Repo.get(Group, user_group.group_id)
      Users.assign_user_roles_for_group(user, group)
    end)

    process_batch(next)
  end

  defp find_next(headers) do
    header =
      Enum.find(headers, fn
        {"link", link} ->
          String.contains?(link, "next")

        _ ->
          false
      end)

    if header do
      {"link", link} = header
      parsed = URI.parse(link)
      query = URI.decode_query(parsed.query)
      query["after"]
    else
      nil
    end
  end

  defp okta_client, do: Application.get_env(:velocity, :okta_client, Velocity.Clients.Okta)

  defp user_groups_or_sleep(okta_user_uid) do
    case okta_client().get_user_groups(okta_user_uid) do
      {:ok, response} ->
        maybe_sleep(response)
    end
  end

  defp list_active_users_or_sleep(cursor) do
    case okta_client().list_active_users(cursor) do
      {:ok, response} ->
        maybe_sleep(response)
    end
  end

  defp find_header(headers, header) do
    {_, value} =
      Enum.find(headers, fn
        {^header, _} ->
          true

        _ ->
          false
      end)

    value
  end

  defp maybe_sleep(response = %{headers: headers}) do
    rate_limit_remaining = String.to_integer(find_header(headers, "x-rate-limit-remaining"))

    if rate_limit_remaining < 10 do
      rate_limit_reset = String.to_integer(find_header(headers, "x-rate-limit-reset"))
      sleep_until(rate_limit_reset)
    end

    {:ok, response}
  end

  defp sleep_until(unix_time) do
    if :os.system_time(:seconds) < unix_time do
      seconds = unix_time - :os.system_time(:seconds) + 1

      if seconds > 0 do
        Logger.info("sleeping until #{unix_time}. (#{seconds}) seconds.")
        :timer.sleep(seconds * 1000)
      end

      sleep_until(unix_time)
    else
      :ok
    end
  end

  defp get_user_groups_params(user_groups, user) do
    inserted_and_updated_at = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    groups = Groups.all()

    matching_groups =
      Enum.filter(groups, fn group ->
        Enum.any?(user_groups, fn
          %{"profile" => %{"name" => group_slug}} ->
            group_slug == group.okta_group_slug

          unknown ->
            Logger.error("unknown error getting user_group #{inspect(unknown)}")
            false
        end)
      end)

    Enum.map(matching_groups, fn group ->
      %{
        user_id: user.id,
        group_id: group.id,
        inserted_at: inserted_and_updated_at,
        updated_at: inserted_and_updated_at
      }
    end)
  end
end
