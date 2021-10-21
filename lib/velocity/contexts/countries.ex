defmodule Velocity.Contexts.Countries do
  @moduledoc "context for countries"

  alias Velocity.Repo
  alias Velocity.Schema.Address
  alias Velocity.Schema.Country
  alias Velocity.Schema.User
  import Ecto.Query

  def all do
    Repo.all(Country)
  end

  def get_by(keyword) do
    Repo.get_by(Country, keyword)
  end

  def user_country_of_employment(user_id) do
    country_query =
      from(c in Country,
        select: %{
          id: c.id,
          iso_alpha_2_code: c.iso_alpha_2_code,
          name: c.name,
          description: c.description
        },
        left_join: a in Address,
        on: a.country_id == c.id,
        left_join: u in User,
        on: u.work_address_id == a.id,
        where: u.id == ^user_id
      )

    Repo.one(country_query)
  end
end
