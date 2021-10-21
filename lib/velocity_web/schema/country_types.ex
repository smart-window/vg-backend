defmodule VelocityWeb.Schema.CountryTypes do
  @moduledoc false
  use Absinthe.Schema.Notation
  alias Velocity.Repo

  @desc "country"
  object :country do
    field :id, :id
    field :iso_alpha_2_code, :string
    field :name, :string
    field :region_id, :id
    field :latitude, :float
    field :longitude, :float

    field(:region, :region) do
      resolve(fn country, _args, _info ->
        region = Ecto.assoc(country, :region) |> Repo.one()
        {:ok, region}
      end)
    end
  end
end
