defmodule Velocity.Repo.Migrations.AddUniqueIndexToStageTemplates do
  use Ecto.Migration

  def up do
    alter table(:stage_templates) do
      modify(:order, :integer, null: false)
      modify(:name, :string, null: false)
    end

    create index(:stage_templates, [:name, :process_template_id], unique: true)
  end

  def down do
    alter table(:stage_templates) do
      modify(:order, :integer, null: true)
      modify(:name, :string, null: true)
    end

    drop index(:stage_templates, [:name, :process_template_id], unique: true)
  end
end
