defmodule VelocityWeb.Schema.ClientTypes do
  @moduledoc false
  use Absinthe.Schema.Notation

  alias Velocity.Repo
  alias Velocity.Schema.Client
  alias Velocity.Schema.ClientContact
  alias Velocity.Schema.ClientManager
  alias Velocity.Schema.Contract
  alias Velocity.Schema.Employment
  alias Velocity.Schema.User
  alias Velocity.Schema.ClientTeam
  alias Velocity.Schema.TeamUser

  import Ecto.Query

  @desc "client"
  object :client do
    field :id, :id
    field :name, :string
    field :operational_tier, :string
    field :timezone, :string

    field(:client_account_manager, :user) do
      resolve(fn c, _args, _info ->
        client_account_manager =
          Repo.one(
            from(user in User,
              left_join: role in assoc(user, :roles),
              as: :role,
              left_join: client_team in ClientTeam,
              on: ^c.id == client_team.client_id,
              left_join: team_user in TeamUser,
              on: client_team.team_id == team_user.team_id,
              where: role.slug == "ClientAccountManager" and user.id == team_user.user_id
            )
          )

        {:ok, client_account_manager}
      end)
    end

    field(:mpocs, list_of(:client_contact)) do
      resolve(fn c, _args, _info ->
        client_contacts =
          Repo.all(
            from(cc in ClientContact, where: cc.client_id == ^c.id and cc.is_primary == true)
          )

        {:ok, client_contacts}
      end)
    end

    field(:secondary_contacts, list_of(:client_contact)) do
      resolve(fn c, _args, _info ->
        client_contacts =
          Repo.all(
            from(cc in ClientContact, where: cc.client_id == ^c.id and cc.is_primary == false)
          )

        {:ok, client_contacts}
      end)
    end

    field(:active_employments, list_of(:employment)) do
      resolve(fn c, _args, _info ->
        employment =
          Repo.all(
            from(employment in Employment,
              as: :employment,
              left_join: contract in Contract,
              on: contract.id == employment.contract_id,
              left_join: client in Client,
              on: client.id == contract.client_id,
              where:
                not is_nil(employment.effective_date) and is_nil(employment.end_date) and
                  client.id == ^c.id
            )
          )

        {:ok, employment}
      end)
    end

    field(:email, :string) do
      resolve(fn _client, _args, _info ->
        {:ok, "client@example.com"}
      end)
    end

    field(:phone_number, :string) do
      resolve(fn _client, _args, _info ->
        {:ok, "+12816038895"}
      end)
    end

    field(:client_managers, list_of(:client_manager)) do
      resolve(fn client, _args, _info ->
        managers = Repo.all(from cm in ClientManager, where: cm.client_id == ^client.id)
        {:ok, managers}
      end)
    end

    field(:address, :address) do
      resolve(fn client, _args, _info ->
        address = Ecto.assoc(client, :address) |> Repo.one()
        {:ok, address}
      end)
    end

    field(:operating_countries, list_of(:client_operating_country)) do
      resolve(fn client, _args, _info ->
        operating_countries = Ecto.assoc(client, :client_operating_countries) |> Repo.all()
        {:ok, operating_countries}
      end)
    end

    field(:meetings, list_of(:meeting)) do
      resolve(fn client, _args, _info ->
        meetings = Ecto.assoc(client, :meetings) |> Repo.all()
        {:ok, meetings}
      end)
    end

    field(:sent_emails, list_of(:sent_email)) do
      resolve(fn client, _args, _info ->
        sent_emails = Ecto.assoc(client, :sent_emails) |> Repo.all()
        {:ok, sent_emails}
      end)
    end
  end

  object :client_report_item do
    field :id, :id
    field :client_name, :string
    field :region_name, :string
    field :total_employees, :integer
    field :active_employees, :integer

    field(:operating_countries, list_of(:client_operating_country)) do
      resolve(fn client_report_item, _args, _info ->
        client =
          Client
          |> Repo.get(client_report_item.id)
          |> Repo.preload(:client_operating_countries)

        {:ok, client.client_operating_countries}
      end)
    end
  end

  object :client_general do
    field :id, :id
    field :segment, :string
    field :industry_vertical, :string
    field :international_market_operating_experience, :string
    field :other_peo_experience, :string
  end

  object :client_goals do
    field :id, :id
    field :expansion_goals, :string
    field :previous_solutions, :string
    field :goals_and_expectations, :string
    field :pain_points_and_challenges, :string
    field :special_onboarding_instructions, :string
  end

  object :client_interaction_notes do
    field :id, :id
    field :interaction_highlights, :string
    field :interaction_challenges, :string
  end

  object :client_referral_information do
    field :id, :id
    field :partner_referral, :string
    field :partner_stakeholder, :string
    field :other_referral_information, :string
  end

  object :client_payments_and_pricing do
    field :id, :id
    field :standard_payment_terms, :string
    field :payment_type, :string
    field :pricing_structure, :string
    field :pricing_notes, :string
  end

  object :paginated_clients_report do
    field :row_count, :integer
    field :client_report_items, list_of(:client_report_item)
  end
end
