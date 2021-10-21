defmodule Velocity.Repo.Migrations.AddFieldsToEmailTemplates do
  use Ecto.Migration

  def change do
    alter table(:email_templates) do
      add :subject, :string
      add :to_role, :string
      add :from_role, :string
    end
  end
end
