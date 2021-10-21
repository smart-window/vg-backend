defmodule Velocity.Schema.Client do
  @moduledoc "schema for client"
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Address
  alias Velocity.Schema.ClientContact
  alias Velocity.Schema.ClientMeeting
  alias Velocity.Schema.ClientOperatingCountry
  alias Velocity.Schema.ClientSentEmail
  alias Velocity.Schema.ClientTeam
  alias Velocity.Schema.User
  alias Velocity.Utils.Changesets, as: Utils

  schema "clients" do
    field :name, :string
    field :timezone, :string
    field :operational_tier, OperationalTierTypeEnum
    field :segment, ClientSegmentTypeEnum
    field :industry_vertical, :string
    field :international_market_operating_experience, :string
    field :other_peo_experience, :string
    field :expansion_goals, :string
    field :previous_solutions, :string
    field :goals_and_expectations, :string
    field :pain_points_and_challenges, :string
    field :special_onboarding_instructions, :string
    field :salesforce_id, :string
    field :netsuite_id, :string
    field :interaction_highlights, :string
    field :interaction_challenges, :string
    field :partner_referral, :string
    field :partner_stakeholder, :string
    field :other_referral_information, :string
    field :standard_payment_terms, :string
    field :payment_type, PaymentTypeEnum
    field :pricing_structure, :string
    field :pricing_notes, :string
    field :pega_pk, :string
    field :pega_ak, :string

    belongs_to :address, Address

    has_many :users, User

    has_many :client_teams, ClientTeam
    has_many :teams, through: [:client_teams, :team]

    has_many :client_meetings, ClientMeeting
    has_many :meetings, through: [:client_meetings, :meeting]

    has_many :client_sent_emails, ClientSentEmail
    has_many :sent_emails, through: [:client_sent_emails, :sent_email]

    has_many :client_operating_countries, ClientOperatingCountry

    has_many :client_contacts, ClientContact

    timestamps()
  end

  @doc false
  def changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [
      :name,
      :timezone,
      :operational_tier,
      :industry_vertical,
      :international_market_operating_experience,
      :other_peo_experience,
      :segment,
      :expansion_goals,
      :previous_solutions,
      :goals_and_expectations,
      :pain_points_and_challenges,
      :special_onboarding_instructions,
      :interaction_highlights,
      :interaction_challenges,
      :partner_referral,
      :partner_stakeholder,
      :other_referral_information,
      :standard_payment_terms,
      :payment_type,
      :pricing_structure,
      :salesforce_id,
      :netsuite_id,
      :pricing_notes,
      :pega_pk,
      :pega_ak
    ])
    |> validate_required([:name])
    |> unique_constraint([:name])
    |> Utils.maybe_put_assoc(:address, attrs)
  end
end
