defmodule Velocity.Repo.Migrations.AddUniqueIndexToEmailTemplates do
  use Ecto.Migration

  def up do
    create index(:email_templates, [:name], unique: true)
  end

  def down do
    drop index(:email_templates, [:name], unique: true)
  end
end
