defmodule Velocity.Repo.Migrations.CreateClientOnboardings do
  use Ecto.Migration

  def change do
    create table(:client_onboardings) do
      add :contract_id, references(:contracts), null: false
      add :process_id, references(:processes), null: false

      timestamps()
    end
  end
end
