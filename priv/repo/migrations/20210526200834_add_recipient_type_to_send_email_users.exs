defmodule Velocity.Repo.Migrations.AddRecipientTypeToSendEmailUsers do
  use Ecto.Migration

  def change do
    EmailRecipientTypeEnum.create_type()

    alter table(:sent_email_users) do
      add :recipient_type, EmailRecipientTypeEnum.type()
    end
  end
end
