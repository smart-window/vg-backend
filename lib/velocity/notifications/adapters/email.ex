defmodule Velocity.Notifications.Adapters.Email do
  @moduledoc """
  adapter to send Email notifications
  """
  @behaviour Velocity.Notifications.Adapter

  alias Velocity.Notifications.Adapters.Email.Mailer
  alias Velocity.Notifications.Adapters.Email.Types

  def perform(user, notification) do
    Types.notification_email(user["email"], notification["title"], notification["body"])
    |> Mailer.deliver_now()

    :ok
  end
end
