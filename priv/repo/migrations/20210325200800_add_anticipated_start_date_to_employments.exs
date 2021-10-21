defmodule Velocity.Repo.Migrations.AddAnticipatedStartDateToEmployments do
  use Ecto.Migration

  def change do
    alter table(:employments) do
      add :anticipated_start_date, :date
    end
  end
end
