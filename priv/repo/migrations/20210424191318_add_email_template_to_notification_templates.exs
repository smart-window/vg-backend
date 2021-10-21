defmodule Velocity.Repo.Migrations.AddEmailTemplateToNotificationTemplates do
  use Ecto.Migration

  def change do
    alter table(:notification_templates) do
      add :email_template_id, references(:email_templates)
    end
  end
end
