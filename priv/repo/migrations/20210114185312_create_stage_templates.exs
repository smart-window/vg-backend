defmodule Velocity.Repo.Migrations.CreateStageTemplates do
  use Ecto.Migration

  def change do
    create table(:stage_templates) do
      add :order, :integer
      add :name, :string
      add :process_template_id, references(:process_templates, on_delete: :nothing)

      timestamps()
    end

    create index(:stage_templates, [:process_template_id])
  end
end
