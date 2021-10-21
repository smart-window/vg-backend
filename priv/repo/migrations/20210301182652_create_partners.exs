defmodule Velocity.Repo.Migrations.CreatePartners do
  use Ecto.Migration

  def change do
    create table(:partners) do
      add :address_id, references(:addresses), null: true
      add :name, :string
      add :netsuite_id, :string
      add :statement_of_work_with, :string
      add :deployment_agreement_with, :string
      add :contact_guidelines, :string

      add :pega_pk, :string
      add :pega_ak, :string

      timestamps()
    end
  end
end
