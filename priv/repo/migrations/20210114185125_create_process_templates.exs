defmodule Velocity.Repo.Migrations.CreateProcessTemplates do
  use Ecto.Migration

  def change do
    create table(:process_templates) do
      add :type, :string

      timestamps()
    end
  end
end
