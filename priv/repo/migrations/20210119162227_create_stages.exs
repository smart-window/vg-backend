defmodule Velocity.Repo.Migrations.CreateStages do
  use Ecto.Migration

  def change do
    create table(:stages) do
      add :name, :string
      add :percent_complete, :float, default: 0
      add :process_id, references(:processes, on_delete: :nothing)
      add :stage_template_id, references(:stage_templates, on_delete: :nothing)

      timestamps()
    end

    create index(:stages, [:process_id])
  end
end
