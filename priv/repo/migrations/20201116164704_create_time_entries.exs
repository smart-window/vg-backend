defmodule Velocity.Repo.Migrations.CreateTimeEntries do
  use Ecto.Migration

  def change do
    create table(:time_entries) do
      add :event_date, :date
      add :description, :string
      add :total_hours, :float
      add :metadata, :json
      add :time_type_id, references(:time_types)
      add :user_id, references(:users)
      add :time_policy_id, references(:time_policies)

      timestamps()
    end
  end
end
