defmodule Velocity.Notifications.Adapters.Email.Types do
  @moduledoc """
  Bamboo email creation
  """
  import Bamboo.Email

  def notification_email(to, title, body) do
    new_email(
      to: to,
      from: "support@myapp.com",
      subject: title,
      html_body: body,
      text_body: body
    )
  end
end
