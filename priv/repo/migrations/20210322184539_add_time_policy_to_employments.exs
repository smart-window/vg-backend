defmodule Velocity.Repo.Migrations.AddTimePolicyToEmployments do
  use Ecto.Migration

  def change do
    alter table(:employments) do
      add :time_policy_id, references(:time_policies)
    end
  end
end
