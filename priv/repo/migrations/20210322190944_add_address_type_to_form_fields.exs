defmodule Velocity.Repo.Migrations.AddAddressTypeToFormFields do
  use Ecto.Migration

  def change do
    execute """
      ALTER TYPE form_field_type ADD VALUE IF NOT EXISTS 'address';
    """
  end
end
