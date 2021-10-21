defmodule Velocity.Repo.Migrations.CreateContracts do
  use Ecto.Migration

  def change do
    create table(:contracts) do
      add :client_id, references(:clients), null: false

      add :pega_pk, :string
      add :pega_ak, :string

      timestamps()
    end
  end
end
