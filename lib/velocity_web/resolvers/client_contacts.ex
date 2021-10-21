defmodule VelocityWeb.Resolvers.ClientContacts do
  @moduledoc """
  GQL resolver for client contacts
  """

  alias Velocity.Contexts.ClientContacts

  def upsert_mpoc(args, _) do
    ClientContacts.upsert_mpoc(args)
  end

  def set_region_mpoc(args, _) do
    args = %{
      client_id: String.to_integer(args.client_id),
      user_id: String.to_integer(args.user_id),
      region_id: String.to_integer(args.region_id)
    }

    ClientContacts.set_region_mpoc(args)
  end

  def set_organization_mpoc(args, _) do
    args = %{
      client_id: String.to_integer(args.client_id),
      user_id: String.to_integer(args.user_id)
    }

    ClientContacts.set_organization_mpoc(args)
  end

  def insert_secondary_contact(args, _) do
    ClientContacts.insert_secondary_contact(args)
  end

  def delete_secondary_contact(args, _) do
    ClientContacts.delete_secondary_contact(String.to_integer(args.id))
  end
end
