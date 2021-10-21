defmodule Velocity.Contexts.PartnerContacts do
  @moduledoc """
  The Contexts.PartnerContacts context.
  """

  alias Velocity.Repo

  alias Velocity.Schema.PartnerContact
  alias Velocity.Schema.Partner
  alias Velocity.Schema.PartnerOperatingCountry

  import Ecto.Query

  @doc """
  Returns the list of partner_contacts.

  ## Examples

      iex> list_partner_contacts()
      [%PartnerContact{}, ...]

  """
  def list_partner_contacts do
    Repo.all(PartnerContact)
    |> Repo.preload(:partner)
  end

  @doc """
  Gets a single partner_contact.

  Raises if the Partner contact does not exist.

  ## Examples

      iex> get_partner_contact!(123)
      %PartnerContact{}

  """
  def get_partner_contact!(id), do: Repo.get!(PartnerContact, id) |> Repo.preload(:partner)

  @doc """
  Creates a partner_contact.

  ## Examples

      iex> create_partner_contact(%{field: value})
      {:ok, %PartnerContact{}}

      iex> create_partner_contact(%{field: bad_value})
      {:error, ...}

  """
  def create_partner_contact(attrs \\ %{}) do
    %PartnerContact{}
    |> PartnerContact.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a partner_contact.

  ## Examples

      iex> update_partner_contact(id, %{field: new_value})
      {:ok, %PartnerContact{}}

      iex> update_partner_contact(id, %{field: bad_value})
      {:error, ...}

  """
  def update_partner_contact(id, attrs) do
    Repo.get!(PartnerContact, id)
    |> Repo.preload(:partner)
    |> PartnerContact.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a PartnerContact.

  ## Examples

      iex> delete_partner_contact(partner_contact)
      {:ok, %PartnerContact{}}

      iex> delete_partner_contact(partner_contact)
      {:error, ...}

  """
  def delete_partner_contact(id) do
    %PartnerContact{id: id}
    |> Repo.delete()
  end

  @doc """
  Returns a data structure for tracking partner_contact changes.

  ## Examples

      iex> change_partner_contact(partner_contact)
      %Todo{...}

  """
  def change_partner_contact(partner_contact = %PartnerContact{}, attrs \\ %{}) do
    PartnerContact.changeset(partner_contact, attrs)
  end

  def upsert_partner_mpoc(args) do
    args = Map.put(args, :is_primary, true)

    if id = Map.get(args, :id) do
      partner_contact = Repo.get!(PartnerContact, id)
      PartnerContact.changeset(partner_contact, args) |> Repo.update()
    else
      PartnerContact.changeset(%PartnerContact{}, args) |> Repo.insert()
    end
  end

  def set_partner_region_mpoc(args) do
    partner_id = Map.get(args, :partner_id)
    user_id = Map.get(args, :user_id)

    region_countries_query =
      from(coc in PartnerOperatingCountry,
        join: c in assoc(coc, :country),
        where: c.region_id == ^args.region_id
      )

    partner =
      Repo.get(Partner, partner_id)
      |> Repo.preload(partner_operating_countries: region_countries_query)

    partner_contacts =
      Enum.reduce(partner.partner_operating_countries, [], fn operating_country, acc ->
        country_id = operating_country.country_id

        params = %{
          is_primary: true,
          partner_id: partner_id,
          country_id: country_id
        }

        # check if the given partner has a MPOC in the given country
        mpoc = Repo.get_by(PartnerContact, params)
        params = Map.put(params, :user_id, user_id)

        if is_nil(mpoc) do
          {:ok, partner_contact} = upsert_partner_mpoc(params)
          acc ++ [partner_contact]
        else
          params = Map.put(params, :id, mpoc.id)
          {:ok, partner_contact} = upsert_partner_mpoc(params)
          acc ++ [partner_contact]
        end
      end)

    {:ok, partner_contacts}
  end

  def set_partner_organization_mpoc(args) do
    partner_id = Map.get(args, :partner_id)
    user_id = Map.get(args, :user_id)

    organization_countries_query =
      from(coc in PartnerOperatingCountry,
        where: coc.partner_id == ^args.partner_id
      )

    partner =
      Repo.get(Partner, partner_id)
      |> Repo.preload(partner_operating_countries: organization_countries_query)

    partner_contacts =
      Enum.reduce(partner.partner_operating_countries, [], fn operating_country, acc ->
        country_id = operating_country.country_id

        params = %{
          is_primary: true,
          partner_id: partner_id,
          country_id: country_id
        }

        # check if the given partner has a MPOC in the given country
        mpoc = Repo.get_by(PartnerContact, params)
        params = Map.put(params, :user_id, user_id)

        if is_nil(mpoc) do
          {:ok, partner_contact} = upsert_partner_mpoc(params)
          acc ++ [partner_contact]
        else
          params = Map.put(params, :id, mpoc.id)
          {:ok, partner_contact} = upsert_partner_mpoc(params)
          acc ++ [partner_contact]
        end
      end)

    {:ok, partner_contacts}
  end
end
