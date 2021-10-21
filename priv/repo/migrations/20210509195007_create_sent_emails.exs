defmodule Velocity.Repo.Migrations.CreateSentEmails do
  use Ecto.Migration

  def change do
    create table(:sent_emails) do
      add :description, :string
      add :subject, :string, null: false
      add :body, :text, null: false
      add :sent_date, :date, null: false

      timestamps()
    end
  end
end
