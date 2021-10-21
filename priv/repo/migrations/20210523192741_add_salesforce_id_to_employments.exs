defmodule Velocity.Repo.Migrations.AddSalesforceIdToEmployments do
  use Ecto.Migration

  def change do
    alter table(:employments) do
      add :salesforce_id, :string
    end
  end
end
