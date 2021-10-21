defmodule Velocity.Repo.Migrations.CreateTaskTemplates do
  use Ecto.Migration

  def change do
    create table(:task_templates) do
      add :name, :string
      add :order, :integer
      add :context, :map
      add :completion_type, :string, null: false, default: "check_off"
      add :stage_template_id, references(:stage_templates, on_delete: :nothing)
      add :service_id, references(:services, on_delete: :nothing)

      timestamps()
    end

    create index(:task_templates, [:stage_template_id])
    create index(:task_templates, [:service_id])
  end
end
