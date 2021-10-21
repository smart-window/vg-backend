defmodule Velocity.Schema.Region do
  @moduledoc "schema for region"
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Country

  schema "regions" do
    field :name, :string
    field :latitude, :float
    field :longitude, :float

    has_many :countries, Country

    timestamps()
  end

  @doc false
  def changeset(region, attrs) do
    region
    |> cast(attrs, [:name, :latitude, :longitude])
    |> validate_required([:name])
  end
end
