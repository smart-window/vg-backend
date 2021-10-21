defmodule Velocity.Repo.Migrations.CreateTasks do
  use Ecto.Migration

  def change do
    create table(:tasks) do
      add :order, :integer
      add :stage_id, references(:stages, on_delete: :nothing)
      add :process_id, references(:processes, on_delete: :nothing)
      add :service_id, references(:services, on_delete: :nothing)
      add :task_template_id, references(:task_templates, on_delete: :nothing)
      add :status, :string, null: false, default: "not_started"
      add :completion_type, :string, null: false

      timestamps()
    end

    create index(:tasks, [:stage_id])
  end
end
