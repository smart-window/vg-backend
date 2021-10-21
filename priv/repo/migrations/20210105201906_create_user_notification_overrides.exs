defmodule Velocity.Repo.Migrations.CreateUserNotificationOverrides do
  use Ecto.Migration

  def change do
    create table(:user_notification_overrides) do
      add(:notification_default_id, references(:notification_defaults), null: false)
      add(:user_id, references(:users), null: false)
      add(:should_send, :boolean, null: false)

      timestamps(default: fragment("now()"))
    end
  end
end
