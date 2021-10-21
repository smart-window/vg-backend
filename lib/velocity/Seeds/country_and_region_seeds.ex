defmodule Velocity.Seeds.CountryAndRegionSeeds do
  alias Velocity.Repo
  alias Velocity.Schema.Country
  alias Velocity.Schema.Region

  def create do
    country_region_mapping =
      "./country_to_region_mappings.csv"
      |> Path.expand(__DIR__)
      |> File.stream!()
      |> CSV.decode(headers: true)
      |> Enum.map(fn {:ok, country_to_region} ->
        country_to_region
      end)
      |> Map.new(&{&1["country_alpha_2"], &1["region"]})

    regions =
      "./regions.csv"
      |> Path.expand(__DIR__)
      |> File.stream!()
      |> CSV.decode(headers: true)
      |> Enum.map(fn {:ok, region} ->
        {latitude, _} = Float.parse(region["latitude"])
        {longitude, _} = Float.parse(region["longitude"])

        Repo.insert!(
          %Region{
            latitude: latitude,
            longitude: longitude,
            name: region["region"]
          },
          on_conflict: {:replace, [:latitude, :longitude]},
          conflict_target: :name
        )
      end)

    "./countries.csv"
    |> Path.expand(__DIR__)
    |> File.stream!()
    |> CSV.decode(separator: ?;, headers: true)
    |> Enum.map(fn {:ok, country} ->
      {latitude, _} = Float.parse(country["latitude"])
      {longitude, _} = Float.parse(country["longitude"])
      country_region = country_region_mapping[country["alpha_2_code"]]

      region_id =
        if country_region do
          region = Enum.find(regions, fn region -> region.name == country_region end)
          region.id
        else
          nil
        end

      Repo.insert!(
        %Country{
          iso_alpha_2_code: country["alpha_2_code"],
          iso_alpha_3_code: country["alpha_3_code"],
          latitude: latitude,
          longitude: longitude,
          name: country["country"],
          description: "",
          region_id: region_id
        },
        on_conflict: {:replace, [:latitude, :longitude, :region_id]},
        conflict_target: :iso_alpha_2_code,
        returning: true
      )
    end)
  end
end
