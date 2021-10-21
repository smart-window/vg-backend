defmodule VelocityWeb.Resolvers.SentEmails do
  @moduledoc """
    resolver for client operating countries
  """

  alias Velocity.Contexts.SentEmails

  def upsert_client_sent_email(args, _) do
    SentEmails.upsert_client_sent_email(args)
  end

  def delete_client_sent_email(args, _) do
    SentEmails.delete_client_sent_email(String.to_integer(args.id))
  end
end
