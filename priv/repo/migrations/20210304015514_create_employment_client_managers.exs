defmodule Velocity.Repo.Migrations.CreateEmploymentClientManagers do
  use Ecto.Migration

  def change do
    create table(:employment_client_managers) do
      add :employment_id, references(:employments), null: false
      add :client_manager_id, references(:client_managers), null: false
      add :effective_date, :date

      add :pega_pk, :string
      add :pega_ak, :string

      timestamps()
    end
  end
end
