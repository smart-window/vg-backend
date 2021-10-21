defmodule Velocity.Repo.Migrations.AddCountrySpecificFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :country_specific_fields, :map
    end
  end
end
