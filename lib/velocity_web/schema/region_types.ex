defmodule VelocityWeb.Schema.RegionTypes do
  @moduledoc false
  use Absinthe.Schema.Notation

  @desc "region"
  object :region do
    field :id, :id
    field :name, :string
    field :latitude, :float
    field :longitude, :float

    field :countries, list_of(:country)
  end
end
