defmodule VelocityWeb.Resolvers.PartnerOperatingCountries do
  @moduledoc """
    resolver for partner operating countries
  """

  alias Velocity.Contexts.PartnerOperatingCountries

  def create_partner_operating_country(args, _) do
    PartnerOperatingCountries.create_partner_operating_country(args)
  end

  def update_partner_operating_country(args, _) do
    PartnerOperatingCountries.update_partner_operating_country(args)
  end

  def delete_partner_operating_country(args, _) do
    PartnerOperatingCountries.delete_partner_operating_country(args)
  end
end
