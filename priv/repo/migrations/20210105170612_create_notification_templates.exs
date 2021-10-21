defmodule Velocity.Repo.Migrations.CreateNotificationTemplates do
  use Ecto.Migration

  def change do
    create table(:notification_templates) do
      add(:event, :string)
      add(:title, :string)
      add(:body, :text)
      add(:image_url, :string)

      timestamps(default: fragment("now()"))
    end

    create(unique_index(:notification_templates, [:event]))
  end
end
