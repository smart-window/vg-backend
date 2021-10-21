defmodule Velocity.Repo.Migrations.AddZendeskIdToTeams do
  use Ecto.Migration

  def change do
    alter table(:teams) do
      add :zendesk_id, :string, null: true
    end
  end
end
