defmodule VelocityWeb.Schema.PartnerOperatingCountryTypes do
  @moduledoc false
  use Absinthe.Schema.Notation

  alias Velocity.Repo

  @desc "partner_operating_country"
  object :partner_operating_country do
    field :id, :id
    field :partner_id, :id
    field :country_id, :id
    field :primary_service, :string
    field :secondary_service, :string
    field :bank_charges, :string

    field(:partner_operating_country_services, list_of(:partner_operating_country_service)) do
      resolve(fn partner_operating_country, _args, _info ->
        partner_operating_country_services =
          Ecto.assoc(partner_operating_country, :partner_operating_country_services) |> Repo.all()

        {:ok, partner_operating_country_services}
      end)
    end
  end
end
