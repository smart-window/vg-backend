defmodule Velocity.Schema.Address do
  @moduledoc "schema for address"
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Country

  schema "addresses" do
    field :line_1, :string
    field :line_2, :string
    field :line_3, :string
    field :city, :string
    field :postal_code, :string
    field :county_district, :string
    field :state_province, :string
    field :state_province_iso_alpha_2_code, :string
    field :formatted_address, :string
    belongs_to :country, Country
    field :timezone, :string

    timestamps()
  end

  @doc false
  def changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [:line_1, :description])
    |> validate_required([:line_1])
  end
end
