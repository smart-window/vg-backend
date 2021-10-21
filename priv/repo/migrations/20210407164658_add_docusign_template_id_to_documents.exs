defmodule Velocity.Repo.Migrations.AddDocusignTemplateIdToDocuments do
  use Ecto.Migration

  def change do
    alter table(:documents) do
      add :docusign_template_id, :string
    end
  end
end
