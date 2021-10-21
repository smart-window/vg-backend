defmodule VelocityWeb.Schema.PartnerOperatingCountryServiceTypes do
  @moduledoc false
  use Absinthe.Schema.Notation

  @desc "partner_operating_country_service"
  object :partner_operating_country_service do
    field :id, :id
    field :fee, :float
    field :fee_type, :string
    field :has_setup_fee, :boolean
    field :observation, :string
    field :setup_fee, :float
    field :type, :string
    field :partner_operating_country_id, :id
  end
end
