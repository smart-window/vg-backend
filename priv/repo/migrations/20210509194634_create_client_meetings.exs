defmodule Velocity.Repo.Migrations.CreateClientMeetings do
  use Ecto.Migration

  def change do
    create table(:client_meetings) do
      add :client_id, references(:clients, on_delete: :nothing), null: false
      add :meeting_id, references(:meetings, on_delete: :nothing), null: false

      timestamps()
    end

    create unique_index(:client_meetings, [:client_id, :meeting_id])
    create index(:client_meetings, [:meeting_id])
  end
end
