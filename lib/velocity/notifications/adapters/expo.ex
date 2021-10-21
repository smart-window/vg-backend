defmodule Velocity.Notifications.Adapters.Expo do
  @moduledoc """
  adapter to send Expo push notifications
  """
  @behaviour Velocity.Notifications.Adapter

  def perform(_user, notification) do
    message = %{
      to: "ExponentPushToken[XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX]",
      title: notification.title,
      body: notification.body
    }

    {:ok, _response} = ExponentServerSdk.PushNotification.push(message)
  end
end
