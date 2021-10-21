defmodule Velocity.Repo.Migrations.CreateSentEmailUsers do
  use Ecto.Migration

  def change do
    create table(:sent_email_users) do
      add :email_address, :string, null: false
      add :sent_email_id, references(:sent_emails, on_delete: :nothing), null: false
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:sent_email_users, [:sent_email_id])
    create index(:sent_email_users, [:user_id])
  end
end
