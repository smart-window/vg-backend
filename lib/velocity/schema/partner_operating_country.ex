defmodule Velocity.Schema.PartnerOperatingCountry do
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Country
  alias Velocity.Schema.Partner
  alias Velocity.Schema.PartnerOperatingCountryService

  schema "partner_operating_countries" do
    field :primary_service, :string
    field :secondary_service, :string
    field :bank_charges, :string

    belongs_to :partner, Partner
    belongs_to :country, Country

    has_many :partner_operating_country_services, PartnerOperatingCountryService

    timestamps()
  end

  @doc false
  def changeset(partner_operating_country, attrs) do
    partner_operating_country
    |> cast(attrs, [:partner_id, :country_id, :primary_service, :secondary_service, :bank_charges])
  end
end
