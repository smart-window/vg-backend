defmodule Velocity.Contexts.ClientContacts do
  @moduledoc """
  The Contexts.ClientContacts context.
  """

  alias Velocity.Repo

  alias Velocity.Schema.Client
  alias Velocity.Schema.ClientContact
  alias Velocity.Schema.ClientOperatingCountry
  alias Velocity.Schema.RoleAssignment

  import Ecto.Query

  @doc """
  Returns the list of client_contacts.

  ## Examples

      iex> list_client_contacts()
      [%ClientContact{}, ...]

  """
  def list_client_contacts do
    Repo.all(ClientContact)
    |> Repo.preload(:client)
  end

  @doc """
  Gets a single client_contact.

  Raises `Ecto.NoResultsError` if the Client contact does not exist.

  ## Examples

      iex> get_client_contact!(123)
      %ClientContact{}

      iex> get_client_contact!(456)
      ** (Ecto.NoResultsError)

  """
  def get_client_contact!(id), do: Repo.get!(ClientContact, id) |> Repo.preload(:client)

  @doc """
  Creates a client_contact.

  ## Examples

      iex> create_client_contact(%{field: value})
      {:ok, %ClientContact{}}

      iex> create_client_contact(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_client_contact(attrs \\ %{}) do
    %ClientContact{}
    |> ClientContact.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a client_contact.

  ## Examples

      iex> update_client_contact(id, %{field: new_value})
      {:ok, %ClientContact{}}

      iex> update_client_contact(id, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_client_contact(id, attrs) do
    Repo.get!(ClientContact, id)
    |> Repo.preload(:client)
    |> ClientContact.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a client_contact.

  ## Examples

      iex> delete_client_contact(id)
      {:ok, %ClientContact{}}

      iex> delete_client_contact(id)
      {:error, %Ecto.Changeset{}}

  """
  def delete_client_contact(id) do
    %ClientContact{id: id}
    |> Repo.delete()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking client_contact changes.

  ## Examples

      iex> change_client_contact(client_contact)
      %Ecto.Changeset{data: %ClientContact{}}

  """
  def change_client_contact(client_contact = %ClientContact{}, attrs \\ %{}) do
    ClientContact.changeset(client_contact, attrs)
  end

  def upsert_mpoc(args) do
    args = Map.put(args, :is_primary, true)

    if id = Map.get(args, :id) do
      client_contact = Repo.get!(ClientContact, id)
      ClientContact.changeset(client_contact, args) |> Repo.update()
    else
      ClientContact.changeset(%ClientContact{}, args) |> Repo.insert()
    end
  end

  def set_region_mpoc(args) do
    client_id = Map.get(args, :client_id)
    user_id = Map.get(args, :user_id)

    region_countries_query =
      from(coc in ClientOperatingCountry,
        join: c in assoc(coc, :country),
        where: c.region_id == ^args.region_id
      )

    client =
      Repo.get(Client, client_id)
      |> Repo.preload(client_operating_countries: region_countries_query)

    client_contacts =
      Enum.reduce(client.client_operating_countries, [], fn operating_country, acc ->
        country_id = operating_country.country_id

        params = %{
          is_primary: true,
          client_id: client_id,
          country_id: country_id
        }

        # check if the given client has a MPOC in the given country
        mpoc = Repo.get_by(ClientContact, params)
        params = Map.put(params, :user_id, user_id)

        if is_nil(mpoc) do
          {:ok, client_contact} = upsert_mpoc(params)
          acc ++ [client_contact]
        else
          params = Map.put(params, :id, mpoc.id)
          {:ok, client_contact} = upsert_mpoc(params)
          acc ++ [client_contact]
        end
      end)

    {:ok, client_contacts}
  end

  def set_organization_mpoc(args) do
    client_id = Map.get(args, :client_id)
    user_id = Map.get(args, :user_id)

    organization_countries_query =
      from(coc in ClientOperatingCountry,
        where: coc.client_id == ^args.client_id
      )

    client =
      Repo.get(Client, client_id)
      |> Repo.preload(client_operating_countries: organization_countries_query)

    client_contacts =
      Enum.reduce(client.client_operating_countries, [], fn operating_country, acc ->
        country_id = operating_country.country_id

        params = %{
          is_primary: true,
          client_id: client_id,
          country_id: country_id
        }

        # check if the given client has a MPOC in the given country
        mpoc = Repo.get_by(ClientContact, params)
        params = Map.put(params, :user_id, user_id)

        if is_nil(mpoc) do
          {:ok, client_contact} = upsert_mpoc(params)
          acc ++ [client_contact]
        else
          params = Map.put(params, :id, mpoc.id)
          {:ok, client_contact} = upsert_mpoc(params)
          acc ++ [client_contact]
        end
      end)

    {:ok, client_contacts}
  end

  def insert_secondary_contact(args) do
    %RoleAssignment{}
    |> RoleAssignment.changeset(args)
    |> Repo.insert()

    args = Map.put(args, :is_primary, false)

    %ClientContact{}
    |> ClientContact.changeset(args)
    |> Repo.insert()
  end

  def delete_secondary_contact(id) do
    %ClientContact{id: id}
    |> Repo.delete()
  end
end
