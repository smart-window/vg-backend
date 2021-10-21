defmodule Velocity.Contexts.ClientOperatingCountries do
  @moduledoc "context for clients"

  alias Velocity.Repo
  alias Velocity.Schema.ClientOperatingCountry

  def upsert_operating_country(args) do
    if id = Map.get(args, :id) do
      client_operating_country = Repo.get!(ClientOperatingCountry, id)
      changeset = ClientOperatingCountry.changeset(client_operating_country, args)
      {:ok, Repo.update!(changeset)}
    else
      changeset = ClientOperatingCountry.changeset(%ClientOperatingCountry{}, args)
      {:ok, Repo.insert!(changeset)}
    end
  end

  def delete_operating_country(id) do
    Repo.delete(%ClientOperatingCountry{id: id})
  end
end
