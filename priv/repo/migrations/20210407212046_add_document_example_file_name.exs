defmodule Velocity.Repo.Migrations.AddDocumentExampleFileName do
  use Ecto.Migration

  def change do
    alter table(:documents) do
      add :example_filename, :string
    end

    alter table(:document_templates) do
      add :example_filename, :string
    end
  end
end
