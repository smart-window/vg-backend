defmodule Velocity.Repo.Migrations.ChangeSentDateTypeOnSentEmails do
  use Ecto.Migration

  def up do
    alter table(:sent_emails) do
      modify(:sent_date, :utc_datetime, null: false)
    end
  end

  def down do
    alter table(:sent_emails) do
      modify(:sent_date, :date, null: false)
    end
  end
end
