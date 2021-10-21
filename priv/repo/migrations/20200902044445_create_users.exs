defmodule Velocity.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :first_name, :string
      add :last_name, :string
      add :full_name, :string
      add :email, :string, null: false
      add :okta_user_uid, :string, null: false
      add :company_id, references(:companies)
      add :avatar_url, :string
      add :timezone, :string
      add :nationality_id, references(:countries)
      add :personal_address_id, references(:addresses)
      add :work_address_id, references(:addresses)
      add :birth_date, :utc_datetime
      add :gender, :string
      add :marital_status, :string
      add :visa_work_permit_required, :boolean

      timestamps()
    end

    create(unique_index(:users, [:company_id, :okta_user_uid]))
    create(unique_index(:users, :okta_user_uid))
    create(unique_index(:users, :email))
  end
end
