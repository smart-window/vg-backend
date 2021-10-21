defmodule Velocity.Repo.Migrations.RemovePlannedAbsence do
  use Ecto.Migration

  def change do
    execute "DELETE from time_entries WHERE time_type_id in (SELECT q.time_type_id FROM time_entries q INNER JOIN time_types u on (u.id = q.time_type_id) WHERE u.slug='planned absence')"

    execute "DELETE from time_policy_types WHERE time_type_id in (SELECT q.time_type_id FROM time_policy_types q INNER JOIN time_types u on (u.id = q.time_type_id) WHERE u.slug='planned absence')"

    execute "DELETE from time_types WHERE slug='planned absence'"
  end
end
