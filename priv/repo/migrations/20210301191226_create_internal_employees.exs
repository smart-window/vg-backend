defmodule Velocity.Repo.Migrations.CreateInternalEmployees do
  use Ecto.Migration

  def change do
    create table(:internal_employees) do
      add :employee_id, references(:employees), null: false
      add :job_title, :string
      add :ns_employee_id, :string

      add :pega_pk, :string
      add :pega_ak, :string

      timestamps()
    end
  end
end
