defmodule Velocity.Contexts.Training.EmployeeTrainings do
  @moduledoc "context for employee employee_training"

  import Ecto.Query

  alias Ecto.Multi
  alias Ecto.Query
  alias Velocity.Contexts.Reports
  alias Velocity.Repo
  alias Velocity.Schema.Address
  alias Velocity.Schema.Client
  alias Velocity.Schema.Country
  alias Velocity.Schema.Training.EmployeeTraining
  alias Velocity.Schema.Training.Training
  alias Velocity.Schema.User

  def for_user(user_id) do
    query =
      from(e in EmployeeTraining,
        where: e.user_id == ^user_id
      )

    Repo.all(query)
  end

  def get_by(keyword) do
    Repo.get_by(EmployeeTraining, keyword)
  end

  def create(params) do
    changeset = EmployeeTraining.changeset(%EmployeeTraining{}, params)

    Repo.insert(changeset)
  end

  def create_for_user_and_country(user_id, country_id) do
    inserted_and_updated_at = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    # TODO: set due_date once that meta is added to trainings
    # for now we will set to now + 14 days
    due_date =
      inserted_and_updated_at
      |> NaiveDateTime.add(14 * 24 * 60 * 60, :second)
      |> NaiveDateTime.to_date()

    employee_trainings =
      Repo.all(
        from t in Training,
          join: tc in assoc(t, :training_countries),
          where: tc.country_id == ^country_id
      )
      |> Enum.map(fn training ->
        %{
          training_id: training.id,
          user_id: user_id,
          status: "not_started",
          due_date: due_date,
          inserted_at: inserted_and_updated_at,
          updated_at: inserted_and_updated_at
        }
      end)

    # TODO: need to figure out how to prevent multiple employee training
    # records... can't simply add a unique index of training_id and
    # user_id... what about trainings that need to be performed at
    # an interval? Perhaps some "alternate" identifier can be used
    # for this purpose. So for now the on_conflict check does nothing as
    # there are no unique indices
    Multi.new()
    |> Multi.insert_all(:employee_trainings, EmployeeTraining, employee_trainings,
      on_conflict: :nothing
    )
    |> Repo.transaction()
  end

  def update(params) do
    employee_training = get_by(id: params.id)

    changeset = EmployeeTraining.changeset(employee_training, params)

    Repo.update(changeset)
  end

  def delete(employee_training_id) do
    employee_training = get_by(id: employee_training_id)

    Repo.delete(employee_training)
  end

  def employee_trainings_report(
        page_size,
        sort_column,
        sort_direction,
        last_id,
        last_value,
        filter_by,
        search_by
      ) do
    query =
      employee_trainings_report_query(
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

  def employee_trainings_report_query(
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
    # TODO: left_joins below may be able to change to joins based on data
    # requirements (e.g. client, work address on user required?)
    # NOTE: the training status of 'overdue' is processed virtually
    # so that we don't have to maintain it based on a due date passing
    # the current date, change in due date, etc. hence the 'case when'
    # stuff below and elsewhere
    from et in EmployeeTraining,
      as: :employee_training,
      select: %{
        id: et.id,
        due_date: et.due_date,
        status:
          fragment(
            "case when ? < now() and ? <> 'completed' then 'overdue' else ? end as status",
            et.due_date,
            et.status,
            et.status
          ),
        completed_date: et.completed_date,
        sql_row_count: fragment("count(*) over()")
      },
      join: u in User,
      on: u.id == et.user_id,
      as: :user,
      join: t in Training,
      on: t.id == et.training_id,
      as: :training,
      left_join: c in Client,
      on: c.id == u.client_id,
      as: :client,
      left_join: a in Address,
      on: a.id == u.work_address_id,
      as: :address,
      left_join: cn in Country,
      on: cn.id == a.country_id,
      as: :country,
      select_merge: %{user_last_name: u.last_name},
      select_merge: %{user_first_name: u.first_name},
      select_merge: %{user_full_name: u.full_name},
      select_merge: %{user_okta_user_uid: u.okta_user_uid},
      select_merge: %{training_name: t.name},
      select_merge: %{user_client_name: c.name},
      select_merge: %{user_work_address_country_name: cn.name},
      where: ^last_record_clause,
      where: ^filter_clause,
      where: ^search_clause,
      order_by: ^order_by_clause
  end

  defp build_last_record_clause(0, _last_value, _sort_column, _sort_direction) do
    dynamic(true)
  end

  defp build_last_record_clause(last_id, last_value, sort_column, sort_direction) do
    cond do
      Enum.member?([:due_date, :status, :completed_date], sort_column) ->
        Reports.last_record_clause(
          sort_direction,
          :employee_training,
          :employee_training,
          sort_column,
          last_id,
          last_value
        )

      Enum.member?([:training_name], sort_column) ->
        Reports.last_record_clause(
          sort_direction,
          :employee_training,
          :training,
          :name,
          last_id,
          last_value
        )

      Enum.member?([:last_name, :user_last_name, :user_full_name], sort_column) ->
        Reports.last_record_clause(
          sort_direction,
          :employee_training,
          :user,
          :last_name,
          last_id,
          last_value
        )

      Enum.member?([:client, :user_client_name], sort_column) ->
        Reports.last_record_clause(
          sort_direction,
          :employee_training,
          :client,
          :name,
          last_id,
          last_value
        )

      Enum.member?([:country_name, :user_work_address_country_name], sort_column) ->
        Reports.last_record_clause(
          sort_direction,
          :employee_training,
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

  defp build_order_by_clause(:user_full_name, sort_direction) do
    [{sort_direction, dynamic([user: u], u.last_name)}, asc: :id]
  end

  defp build_order_by_clause(:training_name, sort_direction) do
    [{sort_direction, dynamic([training: t], t.name)}, asc: :id]
  end

  defp build_order_by_clause(:status, sort_direction) do
    [
      {sort_direction,
       dynamic(
         [employee_training: et],
         fragment(
           "case when ? < now() and ? <> 'completed' then 'overdue' else ? end",
           et.due_date,
           et.status,
           et.status
         )
       )},
      asc: :id
    ]
  end

  defp build_order_by_clause(sort_column, sort_direction) do
    [{sort_direction, sort_column}, asc: :id]
  end

  defp build_filter_clause(filter_by) do
    Enum.reduce(filter_by, dynamic(true), fn filter, filter_clause ->
      where_clause = build_filter_where_clause(Macro.underscore(filter.name), filter.value)

      dynamic(
        [employee_training, user, training, client, address, country],
        ^filter_clause and ^where_clause
      )
    end)
  end

  defp build_filter_where_clause("status", value) do
    values = String.split(value, ",")

    Enum.reduce(values, dynamic(false), fn value_item, filter_clause ->
      if value_item == "overdue" do
        dynamic(
          [employee_training: et],
          (et.due_date < fragment("now()") and et.status != "completed") or ^filter_clause
        )
      else
        dynamic([employee_training: et], et.status == ^value_item or ^filter_clause)
      end
    end)
  end

  defp build_filter_where_clause("client", value) do
    client_ids = String.split(value, ",")
    dynamic([client: c], c.id in ^client_ids)
  end

  defp build_filter_where_clause("user_client_name", value) do
    client_ids = String.split(value, ",")
    dynamic([client: c], c.id in ^client_ids)
  end

  defp build_filter_where_clause("country", value) do
    country_ids = String.split(value, ",")
    dynamic([country: cn], cn.id in ^country_ids)
  end

  defp build_filter_where_clause("user_work_address_country_name", value) do
    filter_value = "%#{value}%"
    dynamic([country: cn], like(cn.name, ^filter_value))
  end

  defp build_filter_where_clause("training_name", value) do
    filter_value = "%#{value}%"
    dynamic([training: t], like(t.name, ^filter_value))
  end

  defp build_filter_where_clause("due_date", value) do
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

    dynamic([employee_training: et], et.due_date >= ^start_date and et.due_date <= ^end_date)
  end

  defp build_filter_where_clause("completed_date", value) do
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
      [employee_training: et],
      et.completed_date >= ^start_date and et.completed_date <= ^end_date
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
