defmodule Velocity.Contexts.Pto.AccrualPolicies do
  @moduledoc "context for accrual policies"

  alias Ecto.Multi
  alias Ecto.Query
  alias Velocity.Contexts.Reports
  alias Velocity.Repo
  alias Velocity.Schema.Pto.AccrualPolicy
  alias Velocity.Schema.Pto.Level
  alias Velocity.Schema.Pto.PtoType
  alias Velocity.Schema.Pto.UserPolicy

  import Ecto.Query

  def all do
    Repo.all(AccrualPolicy)
  end

  def find_by_pega_policy_id(pega_policy_id) do
    case get_by(pega_policy_id: pega_policy_id) do
      accrual_policy = %AccrualPolicy{} ->
        {:ok, accrual_policy}

      nil ->
        {:error, "no accrual_policy found for pega_policy_id: " <> pega_policy_id}
    end
  end

  def by_user_id(user_id) do
    query =
      from(a in AccrualPolicy,
        join: up in UserPolicy,
        on: a.id == up.accrual_policy_id,
        where: up.user_id == ^user_id
      )

    Repo.all(query)
  end

  def by_pega_policy_ids(pega_policy_ids) when is_list(pega_policy_ids) do
    query = from(a in AccrualPolicy, where: a.pega_policy_id in ^pega_policy_ids)

    Repo.all(query)
  end

  def delete(pega_policy_id) do
    accrual_policy = get_by(pega_policy_id: pega_policy_id)

    Repo.delete(accrual_policy)
  end

  def update(params) do
    accrual_policy = get_by(pega_policy_id: params.velocity_policy_uid)

    changeset = AccrualPolicy.changeset(accrual_policy, params)

    Repo.update(changeset)
  end

  def create(params, level_opts \\ []) do
    accrual_policy_changeset = AccrualPolicy.build(params)

    multi =
      Multi.new()
      |> Multi.insert(
        :accrual_policy,
        accrual_policy_changeset,
        on_conflict: {:replace_all_except, [:id, :created_at]},
        conflict_target: :pega_policy_id
      )
      |> Multi.merge(fn %{accrual_policy: accrual_policy} ->
        Enum.reduce(Map.get(params, :levels, []), Multi.new(), fn level, acc ->
          level_changeset = Level.build(Map.put(level, :accrual_policy_id, accrual_policy.id))

          Multi.new()
          |> Multi.insert("#{level.pega_level_id}", level_changeset, level_opts)
          |> Multi.prepend(acc)
        end)
      end)

    Repo.transaction(multi)
  end

  def find_or_create(params, opts \\ []) do
    case get_by(pega_policy_id: params.pega_policy_id) do
      nil ->
        create(params, opts)

      accrual_policy = %AccrualPolicy{} ->
        {:ok, %{accrual_policy: accrual_policy}}
    end
  end

  def get_by(keyword) do
    Repo.get_by(AccrualPolicy, keyword)
  end

  def list_by_external_policy_ids(external_policy_ids) do
    Repo.all(from(a in AccrualPolicy, where: a.external_policy_id in ^external_policy_ids))
  end

  def list_by_ids(policy_ids) do
    Repo.all(from(a in AccrualPolicy, where: a.id in ^policy_ids))
  end

  def get_accrual_policy!(id) do
    Repo.get!(AccrualPolicy, id)
  end

  def create_accrual_policy(params) do
    AccrualPolicy.build(params)
    |> Repo.insert()
  end

  def update_accrual_policy(id, params) do
    Repo.get!(AccrualPolicy, id)
    |> AccrualPolicy.changeset(params)
    |> Repo.update()
  end

  def delete_accrual_policy(id) do
    Repo.get!(AccrualPolicy, id)
    |> Repo.delete()
  end

  def accrual_policies_report(
        page_size,
        sort_column,
        sort_direction,
        last_id,
        last_value,
        filter_by,
        search_by
      ) do
    query =
      accrual_policies_query(
        sort_column,
        sort_direction,
        last_id,
        last_value,
        filter_by,
        search_by
      )

    query = Query.limit(query, ^page_size)
    Repo.all(query)
  end

  def accrual_policies_query(
        sort_column,
        sort_direction,
        last_id,
        last_value,
        filter_by,
        search_by
      ) do
    last_record_clause =
      build_last_record_clause(last_id, last_value, sort_column, sort_direction)

    order_by_clause = build_order_by_clause(sort_column, sort_direction)
    filter_clause = build_filter_clause(filter_by)
    search_clause = build_search_clause(search_by)

    from ap in AccrualPolicy,
      as: :accrual_policy,
      left_join: lvl in Level,
      as: :level,
      on: ap.id == lvl.accrual_policy_id,
      left_join: tot in PtoType,
      as: :pto_type,
      on: ap.pto_type_id == tot.id,
      where: ^last_record_clause,
      where: ^filter_clause,
      where: ^search_clause,
      order_by: ^order_by_clause,
      group_by: ap.id,
      select: %{
        id: ap.id,
        name: ap.label,
        time_off_type: fragment("max(name) as time_off_type"),
        accrual_max: fragment("max(accrual_amount) as accrual_max"),
        rollover_max: fragment("max(carryover_limit) as rollover_max"),
        rollover_date: ap.carryover_day,
        num_levels: count(lvl.id),
        sql_row_count: fragment("count(*) over()")
      }
  end

  defp build_last_record_clause(0, _last_value, _sort_column, _sort_direction) do
    dynamic(true)
  end

  defp build_last_record_clause(last_id, last_value, sort_column, sort_direction) do
    cond do
      Enum.member?([:name], sort_column) ->
        Reports.last_record_clause(
          sort_direction,
          :accrual_policy,
          :accrual_policy,
          :label,
          last_id,
          last_value
        )

      Enum.member?([:time_off_type], sort_column) ->
        Reports.last_record_clause(
          sort_direction,
          :accrual_policy,
          :pto_type,
          :name,
          last_id,
          last_value
        )
    end
  end

  defp build_order_by_clause(:name, sort_direction) do
    [{sort_direction, dynamic([accrual_policy: ap], ap.label)}, asc: :id]
  end

  defp build_order_by_clause(:rollover_date, sort_direction) do
    [{sort_direction, dynamic([accrual_policy: ap], ap.carryover_day)}, asc: :id]
  end

  defp build_order_by_clause(:time_off_type, sort_direction) do
    [{sort_direction, dynamic(fragment("time_off_type"))}, asc: :id]
  end

  defp build_order_by_clause(:accrual_max, sort_direction) do
    [{sort_direction, dynamic(fragment("accrual_max"))}, asc: :id]
  end

  defp build_order_by_clause(:rollover_max, sort_direction) do
    [{sort_direction, dynamic(fragment("rollover_max"))}, asc: :id]
  end

  defp build_filter_clause(filter_by) do
    Enum.reduce(filter_by, dynamic(true), fn filter, filter_clause ->
      where_clause = build_filter_where_clause(Macro.underscore(filter.name), filter.value)
      dynamic(^filter_clause and ^where_clause)
    end)
  end

  defp build_filter_where_clause("time_off_type", value) do
    pto_type_ids = String.split(value, ",")
    dynamic([pto_type: tot], tot.id in ^pto_type_ids)
  end

  defp build_search_clause(search_by) do
    if search_by != nil && String.trim(search_by) != "" do
      search_by_value = "#{String.trim(search_by)}:*"

      dynamic(
        [accrual_policy: ap],
        fragment("to_tsvector(?) @@ plainto_tsquery(?)", ap.label, ^search_by_value)
      )
    else
      dynamic(true)
    end
  end
end
