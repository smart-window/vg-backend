defmodule Velocity.Repo.Migrations.CreateTaskSentEmails do
  use Ecto.Migration

  def change do
    create table(:task_sent_emails) do
      add :task_id, references(:tasks, on_delete: :nothing), null: false
      add :sent_email_id, references(:sent_emails, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:task_sent_emails, [:task_id, :sent_email_id], unique: true)
    create index(:task_sent_emails, [:sent_email_id])
  end
end
