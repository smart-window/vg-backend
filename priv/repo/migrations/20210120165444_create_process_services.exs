defmodule Velocity.Repo.Migrations.CreateProcessServices do
  use Ecto.Migration

  def change do
    create table(:process_services) do
      add :process_id, references(:processes, on_delete: :nothing)
      add :service_id, references(:services, on_delete: :nothing)

      timestamps()
    end

    create index(:process_services, [:process_id])
    create index(:process_services, [:service_id])
  end
end
