defmodule Velocity.Repo.Migrations.CreateSentEmailDocuments do
  use Ecto.Migration

  def change do
    create table(:sent_email_documents) do
      add :sent_email_id, references(:sent_emails, on_delete: :nothing), null: false
      add :document_id, references(:documents, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:sent_email_documents, [:sent_email_id, :document_id], unique: true)
    create index(:sent_email_documents, [:document_id])
  end
end
