defmodule Velocity.Notifications do
  @moduledoc """
    Notifications are triggered from "events" in the system.

    Each time an event occurs we determine:

    * should we notify for the given event type?
    * which users should be notified?

    If there are any users that should be notified for the event type the notification delivery is scheduled
  """

  alias Velocity.Contexts.EmailTemplates
  alias Velocity.Contexts.Users
  alias Velocity.Repo
  alias Velocity.Schema.NotificationDefault
  alias Velocity.Schema.NotificationTemplate
  alias Velocity.Schema.UserNotificationOverride

  import Ecto.Query
  require Logger

  def schedule(event, metadata, opts \\ []) do
    schedule_notifications = fn ->
      notification_templates =
        Repo.all(from(nt in NotificationTemplate, where: nt.event == ^Atom.to_string(event)))

      if notification_templates != [] do
        # for each of the notifications that are configured for this event
        Enum.each(notification_templates, fn notification_template ->
          notification_defaults = get_notification_defaults(notification_template)

          # for channels configured for this notification_template
          Enum.each(notification_defaults, fn notification_default ->
            # find the users who should receive the noti
            {channel, users} = notification_recipients(notification_default, metadata)

            # queue the notification at the appropriate time
            queue_notification(
              channel,
              users,
              notification_template,
              notification_default,
              metadata
            )
          end)
        end)
      else
        Logger.info("no notification templates found for event: #{inspect(event)}")
      end
    end

    if Keyword.get(opts, :async) do
      Task.start(schedule_notifications)
    else
      schedule_notifications.()
    end
  end

  defp queue_notification(
         channel,
         users,
         notification_template = %{title: title, body: body},
         %{minutes_from_event: minutes_from_event},
         metadata
       )
       when channel in ["desktop", "mobile", "email"] do
    adapter = get_adapter(channel)

    Enum.each(users, fn user ->
      # add user into metadata
      metadata_with_user = Map.put(metadata, :user, user)
      # fetch email template per user in case country changes which
      # might change the email notification
      email_template =
        if notification_template.email_template_id != nil do
          # TODO: which country to use to filter email template?
          country_id =
            cond do
              Map.has_key?(metadata, :country) ->
                Map.get(metadata, :country).id

              Map.has_key?(metadata, :user) ->
                Map.get(metadata, :user).nationality_id

              true ->
                nil
            end

          EmailTemplates.get_template(
            notification_template.email_template_id,
            country_id,
            metadata
          )
        else
          nil
        end

      time_to_send =
        time_to_send(user, Map.get(metadata, :event_time, DateTime.utc_now()), minutes_from_event)

      title = EmailTemplates.do_substitution(title, metadata_with_user)

      body =
        if email_template do
          Enum.reduce(email_template.html_sections, "", fn section, acc ->
            acc <> section.html
          end)
        else
          EmailTemplates.do_substitution(body, metadata_with_user)
        end

      {:ok, _ack} =
        exq().enqueue_at(Exq, "default", time_to_send, adapter, [
          user,
          %{title: title, body: body}
        ])
    end)
  end

  defp get_notification_defaults(notification_template) do
    notification_defaults =
      Repo.all(
        from(nd in NotificationDefault,
          where: nd.notification_template_id == ^notification_template.id
        )
      )

    if notification_defaults != [] do
      notification_defaults
    else
      Logger.info(
        "no notification defaults set up for this template: #{inspect(notification_template)}"
      )

      []
    end
  end

  defp notification_recipients(notification_default, metadata) do
    users =
      actors(notification_default, metadata) ++
        roles(notification_default) ++
        users(notification_default)

    apply_user_notification_overrides(users, notification_default)
  end

  defp actors(notification_default, metadata) do
    user_ids =
      metadata
      |> Map.take(Enum.map(notification_default.actors || [], &String.to_atom(&1)))
      |> Map.to_list()
      |> Enum.filter(fn {_actor, actor_value} ->
        if is_list(actor_value) do
          actor_value != []
        else
          !!actor_value
        end
      end)
      |> Enum.map(fn
        {_actor, list} when is_list(list) ->
          [first | _] = list

          if is_map(first) do
            Enum.map(list, & &1.id)
          else
            list
          end

        {_actor, user} ->
          user.id
      end)
      |> List.flatten()

    Users.with_id(user_ids)
  end

  defp roles(notification_default) do
    (notification_default.roles || [])
    |> Enum.map(fn role ->
      Users.with_role(role)
    end)
    |> List.flatten()
  end

  defp users(notification_default) do
    Users.with_id(notification_default.user_ids || [])
  end

  defp apply_user_notification_overrides(users, notification_default) do
    user_overrides_for_notification =
      Repo.all(
        from(uno in UserNotificationOverride,
          where: uno.notification_default_id == ^notification_default.id
        )
      )

    {opted_in, opted_out} = Enum.split_with(user_overrides_for_notification, & &1.should_send)

    opted_out_user_ids = Enum.map(opted_out, & &1.user_id)
    opted_in_user_ids = Enum.map(opted_in, & &1.user_id)
    opted_in_users = Users.with_id(opted_in_user_ids)

    not_opted_out_users = Enum.filter(users, &(&1.id not in opted_out_user_ids))

    {notification_default.channel, opted_in_users ++ not_opted_out_users}
  end

  defp time_to_send(_user, event_time, minutes_to_delay) do
    # TODO - this can be expanded to include user time-zone awareness etc.

    if minutes_to_delay > 0 do
      event_time |> Timex.shift(minutes: minutes_to_delay)
    else
      event_time
    end
  end

  defp get_adapter(channel) do
    :velocity
    |> Application.get_env(:notifications)
    |> Keyword.get(String.to_atom(channel))
  end

  defp exq, do: Application.get_env(:velocity, :exq, Exq)
end
