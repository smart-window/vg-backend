defmodule VelocityWeb.Resolvers.EmailTemplates do
  @moduledoc """
  GQL resolver for email templates
  """

  alias Velocity.Contexts.Email
  alias Velocity.Contexts.EmailTemplates
  alias Velocity.Contexts.SentEmails

  def get(args, _info) do
    {:ok, EmailTemplates.get_template(args.id)}
  end

  def get_by_name(args, _info) do
    {:ok, EmailTemplates.get_template_by_name(args.name, args[:country_id], args[:variables])}
  end

  def send_email(args, _info) do
    {:ok, SentEmails.get_sent_email!(Email.send(args))}
  end
end
