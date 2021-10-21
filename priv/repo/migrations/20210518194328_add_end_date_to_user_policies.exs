defmodule Velocity.Repo.Migrations.AddEndDateToUserPolicies do
  use Ecto.Migration

  def change do
    alter table(:user_policies) do
      add :end_date, :date
    end
  end
end
