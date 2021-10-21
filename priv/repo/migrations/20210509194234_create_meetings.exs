defmodule Velocity.Repo.Migrations.CreateMeetings do
  use Ecto.Migration

  def change do
    create table(:meetings) do
      add :meeting_date, :date, null: false
      add :description, :string
      add :notes, :text

      timestamps()
    end
  end
end
