defmodule Velocity.Repo.Migrations.CreateJobs do
  use Ecto.Migration

  def change do
    create table(:jobs) do
      add :client_id, references(:clients), null: false
      add :title, :string

      add :pega_pk, :string
      add :pega_ak, :string

      timestamps()
    end
  end
end
