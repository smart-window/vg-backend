defmodule Velocity.Repo.Migrations.CreateProcesses do
  use Ecto.Migration

  def change do
    create table(:processes) do
      add :status, :string
      add :percent_complete, :float, default: 0
      add :user_id, references(:users, on_delete: :nothing)
      add :process_template_id, references(:process_templates, on_delete: :nothing)

      timestamps()
    end

    create index(:processes, [:process_template_id])
  end
end
