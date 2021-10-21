defmodule Velocity.Schema.ClientContact do
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Client
  alias Velocity.Schema.Country
  alias Velocity.Schema.Person
  alias Velocity.Schema.User
  alias Velocity.Utils.Changesets, as: Utils

  schema "client_contacts" do
    field :is_primary, :boolean
    belongs_to :client, Client
    belongs_to :user, User
    belongs_to :person, Person
    belongs_to :country, Country

    timestamps()
  end

  @doc false
  def changeset(client_contact, attrs) do
    client_contact
    |> cast(attrs, [:is_primary, :client_id, :user_id, :country_id])
    |> Utils.maybe_put_assoc(:client, attrs)
    |> Utils.maybe_put_assoc(:user, attrs)
    |> Utils.maybe_put_assoc(:person, attrs)
    |> Utils.maybe_put_assoc(:country, attrs)
    |> validate_required([:is_primary])
  end
end
