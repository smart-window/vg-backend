defmodule Velocity.Contexts.NotificationTemplates do
  alias Velocity.Repo
  alias Velocity.Schema.EmailTemplate
  alias Velocity.Schema.NotificationDefault
  alias Velocity.Schema.NotificationTemplate

  import Ecto.Query

  require Logger

  # credo:disable-for-this-file Credo.Check.Refactor.Nesting

  @doc """
    notification_templates is assumed to be a list of maps with each map
    representing a notification template to import. This supports updating
    existing notification templates as well.
    The following input format is expected for each notification template map:
      %{
        event: <name of notification template>
        title: <notification subject>
        email_template_name: <name of email template to which notification should be associated>
        notification_defaults: [
          {
            channel: <channel for notification>
            minutes_from_event: <minutes from event>
          },
          ...
        ]
      }
  """
  def import(notification_templates) do
    Repo.transaction(fn ->
      Enum.reduce(notification_templates, [], fn notification_template_config, acc ->
        inserted_and_updated_at =
          NaiveDateTime.utc_now()
          |> NaiveDateTime.truncate(:second)

        notification_template_event = Map.fetch!(notification_template_config, :event)
        email_template_name = Map.get(notification_template_config, :email_template_name)

        email_template_id =
          if email_template_name != nil do
            email_template = Repo.get_by!(EmailTemplate, name: email_template_name)
            email_template.id
          else
            nil
          end

        Repo.insert(
          %NotificationTemplate{
            event: notification_template_event,
            title: Map.get(notification_template_config, :title),
            body: Map.get(notification_template_config, :body),
            image_url: Map.get(notification_template_config, :image_url),
            email_template_id: email_template_id,
            inserted_at: inserted_and_updated_at,
            updated_at: inserted_and_updated_at
          },
          conflict_target: [:event],
          on_conflict: {:replace, [:title, :body, :image_url, :email_template_id, :updated_at]}
        )

        notification_template =
          Repo.get_by!(NotificationTemplate, event: notification_template_event)

        # delete any notification defaults currently defined
        from(nd in NotificationDefault,
          where: nd.notification_template_id == ^notification_template.id
        )
        |> Repo.delete_all()

        # insert new notification defaults
        Map.get(notification_template_config, :notification_defaults, [])
        |> Enum.with_index()
        |> Enum.each(fn {notification_default_config, _index} ->
          Repo.insert(%NotificationDefault{
            notification_template_id: notification_template.id,
            channel: Map.fetch!(notification_default_config, :channel),
            minutes_from_event: Map.get(notification_default_config, :minutes_from_event),
            roles: Map.get(notification_default_config, :roles),
            actors: Map.get(notification_default_config, :actors),
            user_ids: Map.get(notification_default_config, :user_ids),
            inserted_at: inserted_and_updated_at,
            updated_at: inserted_and_updated_at
          })
        end)

        acc ++ [notification_template]
      end)
    end)
  end
end
