defmodule Velocity.Repo.Migrations.AddUniqueConstraintToStages do
  use Ecto.Migration

  def up do
    create index(:stages, [:process_id, :stage_template_id], unique: true)
  end

  def down do
    drop index(:stages, [:process_id, :stage_template_id], unique: true)
  end
end
