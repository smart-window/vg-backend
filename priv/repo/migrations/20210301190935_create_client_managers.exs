defmodule Velocity.Repo.Migrations.CreateClientManagers do
  use Ecto.Migration

  def change do
    create table(:client_managers) do
      add :user_id, references(:users), null: false
      add :client_id, references(:clients), null: false
      add :reports_to_id, references(:client_managers), null: true
      add :job_title, :string
      add :email, :string

      add :pega_pk, :string
      add :pega_ak, :string

      timestamps()
    end
  end
end
