defmodule VelocityWeb.Resolvers.PartnerContacts do
  @moduledoc """
  GQL resolver for partner contacts
  """

  alias Velocity.Contexts.PartnerContacts

  def upsert_partner_mpoc(args, _) do
    PartnerContacts.upsert_partner_mpoc(args)
  end

  def set_partner_region_mpoc(args, _) do
    args = %{
      partner_id: String.to_integer(args.partner_id),
      user_id: String.to_integer(args.user_id),
      region_id: String.to_integer(args.region_id)
    }

    PartnerContacts.set_partner_region_mpoc(args)
  end

  def set_partner_organization_mpoc(args, _) do
    args = %{
      partner_id: String.to_integer(args.partner_id),
      user_id: String.to_integer(args.user_id)
    }

    PartnerContacts.set_partner_organization_mpoc(args)
  end
end
