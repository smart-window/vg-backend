defmodule Velocity.Repo.Migrations.CreateUserAndClientDocumentAssociations do
  use Ecto.Migration

  def change do
    create table(:user_documents) do
      add :document_id, references(:documents)
      add :user_id, references(:users)
      timestamps()
    end

    create table(:client_documents) do
      add :document_id, references(:documents)
      add :client_id, references(:clients)
      timestamps()
    end

    execute """
      INSERT INTO user_documents (document_id, user_id, inserted_at, updated_at) SELECT id, user_id, inserted_at, updated_at FROM documents;
    """
  end
end
