defmodule Velocity.Repo.Migrations.CreatePersons do
  use Ecto.Migration

  def change do
    create table(:persons) do
      add :first_name, :string, null: false
      add :last_name, :string, null: false
      add :full_name, :string, null: false
      add :email_address, :string, null: false
      add :phone, :string, null: true

      timestamps()
    end
  end
end
