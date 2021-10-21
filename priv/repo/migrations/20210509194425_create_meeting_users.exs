defmodule Velocity.Repo.Migrations.CreateMeetingUsers do
  use Ecto.Migration

  def change do
    create table(:meeting_users) do
      add :meeting_id, references(:meetings, on_delete: :nothing), null: false
      add :user_id, references(:users, on_delete: :nothing), null: false

      timestamps()
    end

    create unique_index(:meeting_users, [:meeting_id, :user_id])
    create index(:meeting_users, [:user_id])
  end
end
