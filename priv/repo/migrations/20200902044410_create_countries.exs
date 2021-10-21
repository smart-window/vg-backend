defmodule Velocity.Repo.Migrations.CreateCountries do
  use Ecto.Migration

  def change do
    create table(:countries) do
      add :iso_alpha_2_code, :string, null: false
      add :name, :string, null: false
      add :description, :string

      timestamps()
    end

    create(unique_index(:countries, [:iso_alpha_2_code]))
    create(unique_index(:countries, [:name]))
  end
end
