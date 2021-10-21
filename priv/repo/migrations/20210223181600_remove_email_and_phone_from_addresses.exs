defmodule Velocity.Repo.Migrations.RemoveEmailAndPhoneFromAddresses do
  use Ecto.Migration

  def change do
    alter table(:addresses) do
      remove :personal_phone
      remove :business_phone
      remove :personal_email
      remove :business_email
    end
  end
end
