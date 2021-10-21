defmodule Velocity.Repo.Migrations.AddFormatted_Address do
  use Ecto.Migration

  def change do
    alter table(:addresses) do
      add :formatted_address, :string
    end
  end
end
