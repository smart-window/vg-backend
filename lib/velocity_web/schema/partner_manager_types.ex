defmodule VelocityWeb.Schema.PartnerManagerTypes do
  @moduledoc false
  use Absinthe.Schema.Notation

  alias Velocity.Repo
  alias Velocity.Schema.PartnerContact

  import Ecto.Query

  @desc "partner_manager"
  object :partner_manager do
    field :id, :id
    field :job_title, :string

    field(:partner, :partner) do
      resolve(fn partner_manager, _args, _info ->
        partner = Ecto.assoc(partner_manager, :partner) |> Repo.one()
        {:ok, partner}
      end)
    end

    field(:user, :user) do
      resolve(fn partner_manager, _args, _info ->
        user = Ecto.assoc(partner_manager, :user) |> Repo.one()
        {:ok, user}
      end)
    end

    field(:mpocs, list_of(:partner_contact)) do
      resolve(fn pm, _args, _info ->
        partner_contact =
          PartnerContact
          |> where(is_primary: true, user_id: ^pm.user_id, partner_id: ^pm.partner_id)
          |> Repo.all()

        {:ok, partner_contact}
      end)
    end
  end

  object :partner_manager_report_item do
    field :id, :id
    field :name, :string
    field :job_title, :string
    field :partner_name, :string
    field :region_name, :string
    field :country_name, :string
  end

  object :paginated_partner_managers_report do
    field :row_count, :integer
    field :partner_manager_report_items, list_of(:partner_manager_report_item)
  end
end
