defmodule Velocity.Repo.Migrations.AddUserEeFields do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :preferred_first_name, :string
      add :phone, :string
      add :business_email, :string
      add :personal_email, :string
      add :emergency_contact_name, :string
      add :emergency_contact_relationship, :string
      add :emergency_contact_phone, :string
    end
  end
end
