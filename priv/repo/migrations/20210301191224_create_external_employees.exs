defmodule Velocity.Repo.Migrations.CreateExternalEmployees do
  use Ecto.Migration

  def change do
    create table(:external_employees) do
      add :employee_id, references(:employees), null: false

      add :pega_pk, :string
      add :pega_ak, :string

      timestamps()
    end
  end
end
