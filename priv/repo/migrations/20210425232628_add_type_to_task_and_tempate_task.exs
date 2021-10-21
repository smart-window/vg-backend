defmodule Velocity.Repo.Migrations.AddTypeToTaskAndTempateTask do
  use Ecto.Migration

  def change do
    alter table(:task_templates) do
      add :type, :string
    end

    alter table(:tasks) do
      add :type, :string
    end
  end
end
