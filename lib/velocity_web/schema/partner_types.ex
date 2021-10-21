defmodule VelocityWeb.Schema.PartnerTypes do
  @moduledoc false
  use Absinthe.Schema.Notation

  alias Velocity.Repo
  alias Velocity.Schema.Partner
  alias Velocity.Schema.PartnerContact

  import Ecto.Query

  @desc "partner"
  object :partner do
    field :id, :id
    field :name, :string
    field :netsuite_id, :string
    field :statement_of_work_with, :string
    field :deployment_agreement_with, :string
    field :contact_guidelines, :string
    field :type, :string

    field(:address, :address) do
      resolve(fn address, _args, _info ->
        address = Ecto.assoc(address, :address) |> Repo.one()
        {:ok, address}
      end)
    end

    field(:mpocs, list_of(:partner_contact)) do
      resolve(fn p, _args, _info ->
        partner_contacts =
          Repo.all(
            from(pc in PartnerContact, where: pc.partner_id == ^p.id and pc.is_primary == true)
          )

        {:ok, partner_contacts}
      end)
    end
  end

  object :partner_report_item do
    field :id, :id
    field :partner_name, :string
    field :region_name, :string
    field :total_employees, :integer
    field :active_employees, :integer

    field(:operating_countries, list_of(:partner_operating_country)) do
      resolve(fn partner_report_item, _args, _info ->
        partner =
          Partner
          |> Repo.get(partner_report_item.id)
          |> Repo.preload(:partner_operating_countries)

        {:ok, partner.partner_operating_countries}
      end)
    end
  end

  object :paginated_partners_report do
    field :row_count, :integer
    field :partner_report_items, list_of(:partner_report_item)
  end
end
