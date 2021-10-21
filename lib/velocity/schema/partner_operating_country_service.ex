defmodule Velocity.Schema.PartnerOperatingCountryService do
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.PartnerOperatingCountry

  schema "partner_operating_country_services" do
    field :fee, :float
    field :fee_type, :string
    field :has_setup_fee, :boolean, default: false
    field :observation, :string
    field :setup_fee, :float
    field :type, :string
    # field :partner_operating_country_id, :id

    belongs_to :partner_operating_country, PartnerOperatingCountry

    timestamps()
  end

  @doc false
  def changeset(partner_operating_country_service, attrs) do
    partner_operating_country_service
    |> cast(attrs, [
      :partner_operating_country_id,
      :type,
      :fee_type,
      :has_setup_fee,
      :setup_fee,
      :fee,
      :observation
    ])
    |> validate_required([
      :partner_operating_country_id,
      :type,
      :fee_type,
      :has_setup_fee,
      :setup_fee,
      :fee,
      :observation
    ])
  end
end
