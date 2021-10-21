defmodule Velocity.Schema.Partner do
  @moduledoc "
    schema for partner (ICP, MSP, etc.)
    represents entities that act as ICP, MSP, etc.
  "
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Address
  alias Velocity.Schema.Employment
  alias Velocity.Schema.PartnerContact
  alias Velocity.Schema.PartnerOperatingCountry

  schema "partners" do
    field :name, :string
    field :netsuite_id, :string
    field :statement_of_work_with, :string
    field :deployment_agreement_with, :string
    field :contact_guidelines, :string
    field :type, PartnerTypeEnum

    belongs_to :address, Address
    has_many :employments, Employment

    has_many :partner_operating_countries, PartnerOperatingCountry

    has_many :partner_operating_country_services,
      through: [:partner_operating_countries, :partner_operating_country_service]

    has_many :partner_contacts, PartnerContact

    timestamps()
  end

  @doc false
  def changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [
      :name,
      :netsuite_id,
      :statement_of_work_with,
      :deployment_agreement_with,
      :contact_guidelines
    ])
    |> validate_required([
      :name
    ])
  end
end
