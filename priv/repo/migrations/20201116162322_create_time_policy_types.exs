defmodule Velocity.Repo.Migrations.CreateTimePolicyTypes do
  use Ecto.Migration

  def change do
    create table(:time_policy_types) do
      add :time_type_id, references(:time_types), null: false
      add :time_policy_id, references(:time_policies), null: false

      timestamps()
    end

    create(unique_index(:time_policy_types, [:time_type_id, :time_policy_id]))
  end
end
