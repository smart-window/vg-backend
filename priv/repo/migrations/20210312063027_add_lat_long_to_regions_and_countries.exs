defmodule Velocity.Repo.Migrations.AddLatLongToRegionsAndCountries do
  use Ecto.Migration

  def change do
    alter table(:regions) do
      add :latitude, :float
      add :longitude, :float
    end

    alter table(:countries) do
      add :latitude, :float
      add :longitude, :float
    end
  end
end
