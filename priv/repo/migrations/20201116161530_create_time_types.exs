defmodule Velocity.Repo.Migrations.CreateTimeTypes do
  use Ecto.Migration

  def change do
    create table(:time_types) do
      add :slug, :string
      add :description, :string

      timestamps()
    end

    create(unique_index(:time_types, [:slug]))
  end
end
