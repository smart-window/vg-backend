defmodule Velocity.Repo.Migrations.CreatePtoTypes do
  use Ecto.Migration

  def change do
    create table(:pto_types) do
      add :name, :string, null: false

      add :pega_pk, :string
      add :pega_ak, :string

      timestamps()
    end

    create(unique_index(:pto_types, [:name]))
  end
end
