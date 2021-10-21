defmodule Velocity.Schema.Country do
  @moduledoc "schema for country"
  use Ecto.Schema
  import Ecto.Changeset
  alias Velocity.Schema.Region

  schema "countries" do
    field :iso_alpha_2_code, :string
    field :iso_alpha_3_code, :string
    field :name, :string
    field :description, :string
    field :latitude, :float
    field :longitude, :float

    belongs_to :region, Region

    timestamps()
  end

  @doc false
  def changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [:region_id, :iso_alpha_2_code, :name, :description, :latitude, :longitude])
    |> validate_required([:region_id, :iso_alpha_2_code, :name])
  end
end
