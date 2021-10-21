defmodule Velocity.Repo.Migrations.CreateRegions do
  use Ecto.Migration

  def change do
    create table(:regions) do
      add :name, :string

      add :pega_pk, :string
      add :pega_ak, :string

      timestamps()
    end

    create(unique_index(:regions, [:name]))
  end
end
