defmodule VelocityWeb.Schema.PartnerContactTypes do
  @moduledoc false
  use Absinthe.Schema.Notation

  alias Velocity.Repo

  @desc "partner_contacts"
  object :partner_contact do
    field :id, :id
    field :is_primary, :boolean
    field :partner_id, :id
    field :country_id, :id
    field :user_id, :id

    field(:partner, :partner) do
      resolve(fn partner, _args, _info ->
        partner = Ecto.assoc(partner, :partner) |> Repo.one()
        {:ok, partner}
      end)
    end

    field(:user, :user) do
      resolve(fn user, _args, _info ->
        user = Ecto.assoc(user, :user) |> Repo.one()
        {:ok, user}
      end)
    end

    field(:country, :country) do
      resolve(fn country, _args, _info ->
        country = Ecto.assoc(country, :country) |> Repo.one()
        {:ok, country}
      end)
    end
  end
end
