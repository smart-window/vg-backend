defmodule VelocityWeb.Resolvers.Countries do
  @moduledoc """
    resolver for countries
  """

  alias Velocity.Contexts.Countries

  def all(_args, _) do
    {:ok, Countries.all()}
  end

  def get(args, _) do
    country = Countries.get_by(id: args.country_id)
    {:ok, country}
  end
end
