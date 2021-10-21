defmodule Velocity.Repo.Migrations.CreateHtmlSections do
  use Ecto.Migration

  def change do
    create table(:html_sections) do
      add :html, :text
      add :order, :integer
      add :variables, {:array, :string}
      add :email_template_id, references(:email_templates, on_delete: :nothing)
      add :country_id, references(:countries, on_delete: :nothing)

      timestamps()
    end

    create index(:html_sections, [:email_template_id])
    create index(:html_sections, [:country_id])
  end
end
