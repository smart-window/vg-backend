defmodule Velocity.Notifications.Adapter do
  @moduledoc """
    Defines the callbacks for the a notification adapter

    Adapters must response to a "perform/2" event an provide a mechanism to deliver the notification
  """

  @callback perform(
              user :: Velocity.Schema.User.t(),
              notification :: %{
                title: String.t(),
                body: String.t()
              }
            ) :: :ok | :error
end
