defmodule Velocity.Repo.Migrations.CreateEmployees do
  use Ecto.Migration

  def change do
    create table(:employees) do
      add :user_id, references(:users), null: false

      add :pega_pk, :string
      add :pega_ak, :string

      timestamps()
    end
  end
end
