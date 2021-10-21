defmodule Velocity.Repo.Migrations.AddResolvedStatusToPtoRequests do
  use Ecto.Migration

  def change do
    alter table(:pto_requests) do
      add :resolved_status, :string
    end
  end
end
