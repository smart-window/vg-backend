defmodule Velocity.Repo.Migrations.CreateNotificationDefaults do
  use Ecto.Migration

  def change do
    create table(:notification_defaults) do
      add(:notification_template_id, references(:notification_templates), null: false)
      add(:channel, :string)
      add(:minutes_from_event, :integer, null: false, default: 0)
      add(:roles, {:array, :string})
      add(:actors, {:array, :string})
      add(:user_ids, {:array, :integer})

      timestamps(default: fragment("now()"))
    end
  end
end
