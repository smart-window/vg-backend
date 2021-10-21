defmodule Velocity.Repo.Migrations.CreateClientSentEmails do
  use Ecto.Migration

  def change do
    create table(:client_sent_emails) do
      add :client_id, references(:clients, on_delete: :nothing), null: false
      add :sent_email_id, references(:sent_emails, on_delete: :nothing), null: false

      timestamps()
    end

    create unique_index(:client_sent_emails, [:client_id, :sent_email_id])
    create index(:client_sent_emails, [:sent_email_id])
  end
end
