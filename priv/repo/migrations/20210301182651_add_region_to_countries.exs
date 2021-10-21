defmodule Velocity.Repo.Migrations.AddRegionToCountries do
  use Ecto.Migration

  def change do
    alter table(:countries) do
      add :region_id, references(:regions)
    end
  end
end
