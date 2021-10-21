defmodule Velocity.Repo.Migrations.CreateEmployments do
  use Ecto.Migration

  def change do
    create table(:employments) do
      add :partner_id, references(:partners), null: false
      add :employee_id, references(:employees), null: false
      add :job_id, references(:jobs), null: false
      add :contract_id, references(:contracts), null: false
      add :country_id, references(:countries), null: false
      add :work_address, references(:addresses), null: true
      add :effective_date, :date

      add :pega_pk, :string
      add :pega_ak, :string

      timestamps()
    end
  end
end
