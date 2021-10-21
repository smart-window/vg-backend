defmodule VelocityWeb.Resolvers.ClientOperatingCountries do
  @moduledoc """
    resolver for client operating countries
  """

  alias Velocity.Contexts.ClientOperatingCountries

  def upsert_operating_country(args, _) do
    ClientOperatingCountries.upsert_operating_country(args)
  end

  def delete_operating_country(args, _) do
    ClientOperatingCountries.delete_operating_country(String.to_integer(args.id))
  end
end
