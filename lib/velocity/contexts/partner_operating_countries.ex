defmodule Velocity.Contexts.PartnerOperatingCountries do
  @moduledoc "context for partner operating countries"

  alias Velocity.Repo
  alias Velocity.Schema.PartnerOperatingCountry
  alias Velocity.Schema.PartnerOperatingCountryService

  import Ecto.Query

  def create_partner_operating_country(args) do
    partner_operating_country =
      PartnerOperatingCountry.changeset(%PartnerOperatingCountry{}, args) |> Repo.insert!()

    inserted_and_updated_at = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    params = [
      %{
        partner_operating_country_id: partner_operating_country.id,
        type: "peo_expatriate",
        inserted_at: inserted_and_updated_at,
        updated_at: inserted_and_updated_at
      },
      %{
        partner_operating_country_id: partner_operating_country.id,
        type: "peo_local_national",
        inserted_at: inserted_and_updated_at,
        updated_at: inserted_and_updated_at
      },
      %{
        partner_operating_country_id: partner_operating_country.id,
        type: "immigration",
        inserted_at: inserted_and_updated_at,
        updated_at: inserted_and_updated_at
      },
      %{
        partner_operating_country_id: partner_operating_country.id,
        type: "ess",
        inserted_at: inserted_and_updated_at,
        updated_at: inserted_and_updated_at
      },
      %{
        partner_operating_country_id: partner_operating_country.id,
        type: "recruitment",
        inserted_at: inserted_and_updated_at,
        updated_at: inserted_and_updated_at
      }
    ]

    Repo.insert_all(PartnerOperatingCountryService, params)

    {:ok, partner_operating_country}
  end

  def update_partner_operating_country(args) do
    params = %{
      id: args.service_id,
      fee: args.fee,
      fee_type: args.fee_type,
      has_setup_fee: args.has_setup_fee,
      observation: args.observation,
      setup_fee: args.setup_fee
    }

    if Map.has_key?(args, :service_id) do
      Repo.get!(PartnerOperatingCountryService, params.id)
      |> PartnerOperatingCountryService.changeset(params)
      |> Repo.update()
    end

    Repo.get!(PartnerOperatingCountry, args.id)
    |> PartnerOperatingCountry.changeset(args)
    |> Repo.update()
  end

  def delete_partner_operating_country(args) do
    Repo.delete_all(
      from(pocs in PartnerOperatingCountryService,
        where: pocs.partner_operating_country_id == ^args.id
      )
    )

    Repo.get!(PartnerOperatingCountry, args.id)
    |> PartnerOperatingCountry.changeset(args)
    |> Repo.delete()
  end
end
