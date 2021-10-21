defmodule Velocity.Repo.Migrations.UpdateUserWithTimeTracking do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :current_time_policy_id, references(:time_policies)
    end
  end
end
