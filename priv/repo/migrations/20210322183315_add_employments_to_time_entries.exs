defmodule Velocity.Repo.Migrations.AddEmploymentsToTimeEntries do
  use Ecto.Migration

  def change do
    alter table(:time_entries) do
      add :employment_id, references(:employments)
    end
  end
end
