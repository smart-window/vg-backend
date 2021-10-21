defmodule Velocity.Contexts.TimeTracking do
  @moduledoc "context for time_tracking"

  alias Ecto.Query
  alias Velocity.Contexts.Groups
  alias Velocity.Contexts.Reports
  alias Velocity.Contexts.Users
  alias Velocity.Repo
  alias Velocity.Schema.Client
  alias Velocity.Schema.Contract
  alias Velocity.Schema.Country
  alias Velocity.Schema.Employee
  alias Velocity.Schema.Employment
  alias Velocity.Schema.TimeEntry
  alias Velocity.Schema.TimePolicy
  alias Velocity.Schema.TimePolicyType
  alias Velocity.Schema.TimeType
  alias Velocity.Schema.User
  alias Velocity.Schema.UserGroup
  import Ecto.Query

  def create_time_policy(params) do
    changeset = TimePolicy.changeset(%TimePolicy{}, params)

    Repo.insert(changeset)
  end

  def create_time_entry(params) do
    if can_add_time_entry?(params.user_id, params.event_date, params.total_hours) do
      changeset = TimeEntry.changeset(%TimeEntry{}, params)
      Repo.insert(changeset)
    else
      {:error, "You cannot exceed 24 hours in a day."}
    end
  end

  def get_time_policy_by(keyword) do
    Repo.get_by(TimePolicy, keyword)
  end

  def create_time_type(params) do
    changeset = TimeType.changeset(%TimeType{}, params)

    Repo.insert(changeset)
  end

  def add_time_type_to_time_policy(time_type = %TimeType{}, time_policy = %TimePolicy{}) do
    changeset =
      TimePolicyType.changeset(%TimePolicyType{}, %{
        time_type: time_type,
        time_policy: time_policy
      })

    Repo.insert(changeset)
  end

  def list_time_entries(user = %User{}, start_date, end_date) do
    time_policy_id = user.current_time_policy_id || get_time_policy_by(slug: "default").id
    # for now pull only for current employment (will likely change to support
    # all employments, a specific set of employments, etc.)
    employments =
      from(emp in Employment,
        select: emp.id,
        join: e in Employee,
        on: e.id == emp.employee_id,
        order_by: [desc: emp.effective_date],
        where: e.user_id == ^user.id,
        limit: 1
      )

    query =
      from(te in TimeEntry,
        join: time_type in assoc(te, :time_type),
        where:
          te.employment_id in subquery(employments) and
            te.time_policy_id == ^time_policy_id and
            te.event_date >= ^start_date and
            te.event_date <= ^end_date,
        order_by: te.event_date,
        preload: [:time_type],
        order_by: te.event_date
      )

    Repo.all(query)
  end

  def list_time_entries(user_id, start_date, end_date) do
    user = Users.get_by(id: user_id)
    list_time_entries(user, start_date, end_date)
  end

  def get_time_types(time_policy_id) do
    time_policy = get_time_policy_by(id: time_policy_id)
    with_time_types = Repo.preload(time_policy, :time_types)
    with_time_types.time_types
  end

  def get_all_time_types do
    Repo.all(TimeType)
  end

  def get_time_type(keyword) do
    Repo.get_by(TimeType, keyword)
  end

  def edit_time_entry(time_entry_id, time_entry_params) do
    case Repo.get_by!(TimeEntry, id: time_entry_id) do
      time_entry = %TimeEntry{} ->
        if can_add_time_entry?(
             time_entry_params.user_id,
             time_entry.event_date,
             time_entry_params.total_hours,
             time_entry.total_hours
           ) do
          changeset = TimeEntry.changeset(time_entry, time_entry_params)
          Repo.update(changeset)
        else
          {:error, "You cannot exceed 24 hours in a day."}
        end
    end
  end

  def can_add_time_entry?(user_id, date, hours, entry_hours \\ 0) do
    number_of_hours =
      Repo.one(
        from(te in TimeEntry,
          where: te.user_id == ^user_id and te.event_date == ^date,
          select: sum(te.total_hours)
        )
      ) || 0

    number_of_hours - entry_hours + hours <= 24
  end

  def paged_time_entries(
        page_size,
        sort_column,
        sort_direction,
        last_id,
        last_value,
        filter_by,
        search_by,
        only_ee_entries
      ) do
    query =
      time_entry_report_query(
        sort_column,
        sort_direction,
        last_id,
        last_value,
        filter_by,
        search_by,
        only_ee_entries
      )

    query = Query.limit(query, ^page_size)
    Repo.all(query)
  end

  def time_entry_report_query(
        sort_column,
        sort_direction,
        last_id,
        last_value,
        filter_by,
        search_by,
        only_ee_entries
      ) do
    last_record_clause =
      build_last_record_clause(last_id, last_value, sort_column, sort_direction)

    order_by_clause = build_order_by_clause(sort_column, sort_direction)
    filter_clause = build_filter_clause(filter_by)
    search_clause = build_search_clause(search_by)

    # TODO: left_joins below may be able to change to joins based on data
    # requirements (e.g. client, work address on user required?)
    from(te in TimeEntry,
      as: :time_entry,
      select: %{
        id: te.id,
        description: te.description,
        event_date: te.event_date,
        total_hours: te.total_hours,
        sql_row_count: fragment("count(*) over()")
      },
      join: emp in Employment,
      on: emp.id == te.employment_id,
      as: :employment,
      join: tt in TimeType,
      on: tt.id == te.time_type_id,
      as: :time_type,
      join: e in Employee,
      on: e.id == emp.employee_id,
      as: :employee,
      join: u in User,
      on: u.id == e.user_id,
      as: :user,
      join: ct in Contract,
      on: ct.id == emp.contract_id,
      as: :contract,
      join: c in Client,
      on: c.id == ct.client_id,
      as: :client,
      join: cn in Country,
      on: cn.id == emp.country_id,
      as: :country,
      select_merge: %{user_last_name: u.last_name},
      select_merge: %{user_first_name: u.first_name},
      select_merge: %{user_full_name: u.full_name},
      select_merge: %{user_okta_user_uid: u.okta_user_uid},
      select_merge: %{time_type_slug: tt.slug},
      select_merge: %{user_client_name: c.name},
      select_merge: %{user_work_address_country_name: cn.name},
      where: ^last_record_clause,
      where: ^filter_clause,
      where: ^search_clause,
      order_by: ^order_by_clause
    )
    |> build_user_group_join(only_ee_entries)
  end

  defp build_user_group_join(query, only_ee_entries) do
    customers_group = Groups.get_by(slug: "customers")

    if only_ee_entries do
      query
      |> join(:inner, [te, emp, tt, e, u, ct, c, cn], ug in UserGroup,
        on: ug.user_id == u.id and ug.group_id == ^customers_group.id
      )
    else
      query
    end
  end

  defp build_last_record_clause(0, _last_value, _sort_column, _sort_direction) do
    dynamic(true)
  end

  defp build_last_record_clause(last_id, last_value, sort_column, sort_direction) do
    cond do
      Enum.member?([:event_date, :total_hours], sort_column) ->
        Reports.last_record_clause(
          sort_direction,
          :time_entry,
          :time_entry,
          sort_column,
          last_id,
          last_value
        )

      Enum.member?([:time_category, :time_type_slug], sort_column) ->
        Reports.last_record_clause(
          sort_direction,
          :time_entry,
          :time_type,
          :slug,
          last_id,
          last_value
        )

      Enum.member?([:last_name, :user_last_name, :user_full_name], sort_column) ->
        Reports.last_record_clause(
          sort_direction,
          :time_entry,
          :user,
          :last_name,
          last_id,
          last_value
        )

      Enum.member?([:client, :user_client_name], sort_column) ->
        Reports.last_record_clause(
          sort_direction,
          :time_entry,
          :client,
          :name,
          last_id,
          last_value
        )

      Enum.member?([:country_name, :user_work_address_country_name], sort_column) ->
        Reports.last_record_clause(
          sort_direction,
          :time_entry,
          :country,
          :name,
          last_id,
          last_value
        )
    end
  end

  defp build_order_by_clause(:client, sort_direction) do
    [{sort_direction, dynamic([client: c], c.name)}, asc: :id]
  end

  defp build_order_by_clause(:user_client_name, sort_direction) do
    [{sort_direction, dynamic([client: c], c.name)}, asc: :id]
  end

  defp build_order_by_clause(:country, sort_direction) do
    [{sort_direction, dynamic([country: cn], cn.name)}, asc: :id]
  end

  defp build_order_by_clause(:user_work_address_country_name, sort_direction) do
    [{sort_direction, dynamic([country: cn], cn.name)}, asc: :id]
  end

  defp build_order_by_clause(:last_name, sort_direction) do
    [{sort_direction, dynamic([user: u], u.last_name)}, asc: :id]
  end

  defp build_order_by_clause(:user_last_name, sort_direction) do
    [{sort_direction, dynamic([user: u], u.last_name)}, asc: :id]
  end

  defp build_order_by_clause(:user_full_name, sort_direction) do
    [{sort_direction, dynamic([user: u], u.last_name)}, asc: :id]
  end

  defp build_order_by_clause(:time_category, sort_direction) do
    [{sort_direction, dynamic([time_type: tt], tt.slug)}, asc: :id]
  end

  defp build_order_by_clause(:time_type_slug, sort_direction) do
    [{sort_direction, dynamic([time_type: tt], tt.slug)}, asc: :id]
  end

  defp build_order_by_clause(sort_column, sort_direction) do
    [{sort_direction, sort_column}, asc: :id]
  end

  defp build_filter_clause(filter_by) do
    Enum.reduce(filter_by, dynamic(true), fn filter, filter_clause ->
      where_clause = build_filter_where_clause(Macro.underscore(filter.name), filter.value)

      dynamic(
        [time_entry, employment, time_type, employee, user, contract, client, country],
        ^filter_clause and ^where_clause
      )
    end)
  end

  defp build_filter_where_clause("client", value) do
    client_ids = String.split(value, ",")
    dynamic([client: c], c.id in ^client_ids)
  end

  defp build_filter_where_clause("user_client_id", value) do
    client_ids = String.split(value, ",")
    dynamic([client: c], c.id in ^client_ids)
  end

  defp build_filter_where_clause("country", value) do
    country_ids = String.split(value, ",")
    dynamic([country: cn], cn.id in ^country_ids)
  end

  defp build_filter_where_clause("user_work_address_country_id", value) do
    country_ids = String.split(value, ",")
    dynamic([country: cn], cn.id in ^country_ids)
  end

  defp build_filter_where_clause("time_category", value) do
    slugs = String.split(value, ",")
    dynamic([time_type: tt], tt.slug in ^slugs)
  end

  defp build_filter_where_clause("time_type_slug", value) do
    slugs = String.split(value, ",")
    dynamic([time_type: tt], tt.slug in ^slugs)
  end

  defp build_filter_where_clause("event_date", value) do
    [start_date, end_date] = String.split(value, ":")

    start_date =
      if start_date == "" do
        "0000-01-01"
      else
        start_date
      end

    end_date =
      if end_date == "" do
        "9999-12-31"
      else
        end_date
      end

    dynamic(
      [time_entry: te],
      te.event_date >= ^start_date and te.event_date <= ^end_date
    )
  end

  defp build_search_clause(search_by) do
    if search_by != nil && String.trim(search_by) != "" do
      search_by_value = "#{String.trim(search_by)}:*"

      dynamic(
        [user: u],
        fragment("to_tsvector(?) @@ to_tsquery(?)", u.okta_user_uid, ^search_by_value) or
          fragment("to_tsvector(?) @@ to_tsquery(?)", u.full_name, ^search_by_value)
      )
    else
      dynamic(true)
    end
  end
end
