defmodule Velocity.Repo.Migrations.CreateTimePolicy do
  use Ecto.Migration

  def change do
    create table(:time_policies) do
      add :slug, :string
      add :work_week_start, :integer
      add :work_week_end, :integer

      timestamps()
    end

    create(unique_index(:time_policies, [:slug]))
  end
end
