defmodule Velocity.Repo.Migrations.AddFileTypeToDocuments do
  use Ecto.Migration

  def change do
    alter table(:documents) do
      add :file_type, :string
      remove :mime_type
    end
  end
end
