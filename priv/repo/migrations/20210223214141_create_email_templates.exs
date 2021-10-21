defmodule Velocity.Repo.Migrations.CreateEmailTemplates do
  use Ecto.Migration

  def change do
    create table(:email_templates) do
      add :name, :string

      timestamps()
    end
  end
end
