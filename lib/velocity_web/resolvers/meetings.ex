defmodule VelocityWeb.Resolvers.Meetings do
  @moduledoc """
    resolver for client operating countries
  """

  alias Velocity.Contexts.Meetings

  def upsert_client_meeting(args, _) do
    Meetings.upsert_client_meeting(args)
  end

  def delete_client_meeting(args, _) do
    Meetings.delete_client_meeting(String.to_integer(args.id))
  end
end
