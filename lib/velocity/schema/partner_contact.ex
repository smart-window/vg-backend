defmodule Velocity.Schema.PartnerContact do
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Country
  alias Velocity.Schema.Partner
  alias Velocity.Schema.Person
  alias Velocity.Schema.User
  alias Velocity.Utils.Changesets, as: Utils

  schema "partner_contacts" do
    field :is_primary, :boolean
    belongs_to :partner, Partner
    belongs_to :user, User
    belongs_to :person, Person
    belongs_to :country, Country

    timestamps()
  end

  @doc false
  def changeset(partner_contact, attrs) do
    partner_contact
    |> cast(attrs, [:is_primary, :partner_id, :user_id, :country_id])
    |> Utils.maybe_put_assoc(:partner, attrs)
    |> Utils.maybe_put_assoc(:user, attrs)
    |> Utils.maybe_put_assoc(:person, attrs)
    |> Utils.maybe_put_assoc(:country, attrs)
    |> validate_required([:is_primary])
  end
end
