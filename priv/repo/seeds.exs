alias Velocity.Repo
alias Velocity.Schema.Service
alias Velocity.Schema.TimePolicy
alias Velocity.Schema.TimePolicyType
alias Velocity.Schema.TimeType
alias Velocity.Seeds.CountryAndRegionSeeds
alias Velocity.Seeds.DocumentSeeds
alias Velocity.Seeds.FormSeeds
alias Velocity.Seeds.PermissionsSeeds
alias Velocity.Seeds.ProcessSeeds

Application.put_env(:velocity, :minimal, true)
{:ok, _} = Application.ensure_all_started(:velocity)

inserted_and_updated_at = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

time_policy_map = [
  %{slug: "default", work_week_start: 1, work_week_end: 5}
]

time_policies_params =
  Enum.map(time_policy_map, fn time_policy_item ->
    %{
      slug: time_policy_item.slug,
      work_week_start: time_policy_item.work_week_start,
      work_week_end: time_policy_item.work_week_end,
      inserted_at: inserted_and_updated_at,
      updated_at: inserted_and_updated_at
    }
  end)

{_num, time_policies} =
  Repo.insert_all(TimePolicy, time_policies_params,
    on_conflict: [set: [updated_at: inserted_and_updated_at]],
    conflict_target: :slug,
    returning: true
  )

time_types_slugs = [
  "work time",
  "break time"
]

_time_types =
  Enum.map(time_types_slugs, fn time_types_slug ->
    %{slug: time_types_slug}
  end)

time_types_params =
  Enum.map(
    time_types_slugs,
    fn perm ->
      %{
        slug: perm,
        inserted_at: inserted_and_updated_at,
        updated_at: inserted_and_updated_at
      }
    end
  )

{_num, time_types} =
  Repo.insert_all(TimeType, time_types_params,
    on_conflict: [set: [updated_at: inserted_and_updated_at]],
    conflict_target: :slug,
    returning: true
  )

default_time_policy =
  Enum.find(time_policies, fn time_policy -> time_policy.slug == "default" end)

default_time_policy_slugs = time_types_slugs

time_policy_types = %{
  default_time_policy.id =>
    time_types
    |> Enum.filter(fn %{slug: slug} ->
      Enum.member?(default_time_policy_slugs, slug)
    end)
    |> Enum.map(& &1.id)
}

time_policy_types_params =
  Enum.reduce(time_policy_types, [], fn {time_policy_id, time_types_ids}, acc ->
    time_type_perms =
      Enum.map(time_types_ids, fn type_id ->
        %{
          time_policy_id: time_policy_id,
          time_type_id: type_id,
          inserted_at: inserted_and_updated_at,
          updated_at: inserted_and_updated_at
        }
      end)

    time_type_perms ++ acc
  end)

Repo.insert_all(TimePolicyType, time_policy_types_params,
  on_conflict: [set: [updated_at: inserted_and_updated_at]],
  conflict_target: [:time_type_id, :time_policy_id]
)

service_names = [
  "PEO",
  "Background Check",
  "Immigration",
  "Benefits"
]

service_params =
  Enum.map(service_names, fn name ->
    %{
      name: name,
      inserted_at: inserted_and_updated_at,
      updated_at: inserted_and_updated_at
    }
  end)

Repo.insert_all(Service, service_params, on_conflict: :nothing)

PermissionsSeeds.create()

if Application.get_env(:velocity, :compile_env) == :dev do
  CountryAndRegionSeeds.create()
  # EmployeeSeeds.create()
  ProcessSeeds.create()
  DocumentSeeds.create()
end

FormSeeds.create()
