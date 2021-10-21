defmodule Velocity.Repo.Migrations.AddUniqueIndexToServices do
  use Ecto.Migration

  def up do
    alter table(:services) do
      modify(:name, :string, null: false)
    end

    create index(:services, :name, unique: true)
  end

  def down do
    alter table(:services) do
      modify(:name, :string, null: true)
    end

    drop index(:services, :name, unique: true)
  end
end
