defmodule Velocity.Repo.Migrations.AddUniqueIndexToProcessTemplates do
  use Ecto.Migration

  def up do
    alter table(:process_templates) do
      modify(:type, :string, null: false)
    end

    create index(:process_templates, :type, unique: true)
  end

  def down do
    alter table(:process_templates) do
      modify(:type, :string, null: true)
    end

    drop index(:process_templates, :type, unique: true)
  end
end
