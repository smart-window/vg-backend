defmodule Velocity.Repo.Migrations.CreateServices do
  use Ecto.Migration

  def change do
    create table(:services) do
      add :name, :string

      timestamps()
    end
  end
end
