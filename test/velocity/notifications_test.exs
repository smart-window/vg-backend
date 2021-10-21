defmodule Velocity.NotificationsTest do
  use Velocity.DataCase, async: true

  import Mox

  alias Velocity.Notifications

  describe "Notifications.schedule/2 it sends" do
    setup :verify_on_exit!

    test "it notifies the appropriate user at the appropriate time" do
      user = Factory.insert(:user)
      notification_template = Factory.insert(:notification_template)
      event_time = DateTime.utc_now()

      Factory.insert(:notification_default, %{
        notification_template: notification_template,
        actors: ["user"]
      })

      MockExq
      |> expect(:enqueue_at, fn _module, _queue, time, _adapter, args ->
        noti_user = Enum.at(args, 0)
        notification = Enum.at(args, 1)

        assert DateTime.compare(event_time, time) == :eq
        assert noti_user.id == user.id
        assert notification.title == notification_template.title

        {:ok, :mocked}
      end)

      Notifications.schedule(
        String.to_existing_atom(notification_template.event),
        %Velocity.Event.Metadata{
          user: user,
          event_time: event_time
        }
      )
    end

    test "it allows a user to opt-in to a notification for which they don't match the default" do
      user = Factory.insert(:user)
      notification_template = Factory.insert(:notification_template)
      event_time = DateTime.utc_now()

      notification_default =
        Factory.insert(:notification_default, %{
          notification_template: notification_template,
          actors: ["initiator"]
        })

      Factory.insert(:user_notification_override, %{
        notification_default: notification_default,
        user: user,
        should_send: true
      })

      MockExq
      |> expect(:enqueue_at, fn _module, _queue, time, _adapter, args ->
        noti_user = Enum.at(args, 0)
        notification = Enum.at(args, 1)

        assert DateTime.compare(event_time, time) == :eq
        assert noti_user.id == user.id
        assert notification.title == notification_template.title

        {:ok, :mocked}
      end)

      Notifications.schedule(
        String.to_existing_atom(notification_template.event),
        %Velocity.Event.Metadata{
          event_time: event_time
        }
      )
    end

    test "it sends to arbitrary 'actors'" do
      user = Factory.insert(:user)
      notification_template = Factory.insert(:notification_template)
      event_time = DateTime.utc_now()

      Factory.insert(:notification_default, %{
        notification_template: notification_template,
        actors: ["some_person"]
      })

      MockExq
      |> expect(:enqueue_at, fn _module, _queue, time, _adapter, args ->
        noti_user = Enum.at(args, 0)
        notification = Enum.at(args, 1)

        assert DateTime.compare(event_time, time) == :eq
        assert noti_user.id == user.id
        assert notification.title == notification_template.title

        {:ok, :mocked}
      end)

      Notifications.schedule(String.to_existing_atom(notification_template.event), %{
        some_person: user,
        event_time: event_time
      })
    end

    test "it sends to all users matching a specified role" do
      user = Factory.insert(:user)
      role = Factory.insert(:role)
      Factory.insert(:user_role, %{user: user, role: role})

      notification_template = Factory.insert(:notification_template)
      event_time = DateTime.utc_now()

      Factory.insert(:notification_default, %{
        notification_template: notification_template,
        roles: [role.slug]
      })

      MockExq
      |> expect(:enqueue_at, fn _module, _queue, time, _adapter, args ->
        noti_user = Enum.at(args, 0)
        notification = Enum.at(args, 1)

        assert DateTime.compare(event_time, time) == :eq
        assert noti_user.id == user.id
        assert notification.title == notification_template.title

        {:ok, :mocked}
      end)

      Notifications.schedule(
        String.to_existing_atom(notification_template.event),
        %Velocity.Event.Metadata{
          event_time: event_time
        }
      )
    end

    test "it sends to specific user_ids" do
      user = Factory.insert(:user)
      notification_template = Factory.insert(:notification_template)
      event_time = DateTime.utc_now()

      Factory.insert(:notification_default, %{
        notification_template: notification_template,
        user_ids: [user.id]
      })

      MockExq
      |> expect(:enqueue_at, fn _module, _queue, time, _adapter, args ->
        noti_user = Enum.at(args, 0)
        notification = Enum.at(args, 1)

        assert DateTime.compare(event_time, time) == :eq
        assert noti_user.id == user.id
        assert notification.title == notification_template.title

        {:ok, :mocked}
      end)

      Notifications.schedule(
        String.to_existing_atom(notification_template.event),
        %Velocity.Event.Metadata{
          event_time: event_time
        }
      )
    end
  end

  describe "Notifications.schedule/2 it does not send" do
    test "it does not schedule a notification if the user has an override set to false" do
      user = Factory.insert(:user)
      notification_template = Factory.insert(:notification_template)
      event_time = DateTime.utc_now()

      notification_default =
        Factory.insert(:notification_default, %{
          notification_template: notification_template,
          actors: ["user"]
        })

      Factory.insert(:user_notification_override, %{
        notification_default: notification_default,
        user: user,
        should_send: false
      })

      MockExq
      |> expect(:enqueue_at, fn _module, _queue, _time, _adapter, args ->
        refute args
      end)

      Notifications.schedule(
        String.to_existing_atom(notification_template.event),
        %Velocity.Event.Metadata{
          user: user,
          event_time: event_time
        }
      )
    end
  end
end
