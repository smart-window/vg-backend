defmodule Velocity.Contexts.Employees do
  @moduledoc "context for employees"

  alias Ecto.Query
  alias Velocity.Repo
  alias Velocity.Schema.Address
  alias Velocity.Schema.Client
  alias Velocity.Schema.Country
  alias Velocity.Schema.Employee
  alias Velocity.Schema.Employment
  alias Velocity.Schema.Partner
  alias Velocity.Schema.Region
  alias Velocity.Schema.User

  import Ecto.Query

  def get!(id) do
    Repo.get!(Employee, id)
  end

  def get_by!(keyword) do
    Repo.get_by!(Employee, keyword)
  end

  def create(params) do
    %Employee{}
    |> Employee.changeset(params)
    |> Repo.insert()
  end

  def update(params) do
    Repo.get!(Employee, params.id)
    |> Employee.changeset(params)
    |> Repo.update()
  end

  def delete(id) do
    %Employee{id: id}
    |> Repo.delete()
  end

  def paginated_employees_report(
        page_size,
        sort_column,
        sort_direction,
        last_id,
        last_value,
        filter_by,
        search_by
      ) do
    query =
      employees_report_query(
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

  def employees_report_query(
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

    from e in Employee,
      join: em in Employment,
      as: :employment,
      on: em.employee_id == e.id,
      join: p in Partner,
      as: :partner,
      on: em.partner_id == p.id,
      join: u in User,
      on: u.id == e.user_id,
      as: :user,
      left_join: c in Client,
      as: :client,
      on: c.id == u.client_id,
      left_join: a in Address,
      as: :address,
      on: a.id == u.work_address_id,
      left_join: cn in Country,
      as: :country,
      on: cn.id == em.country_id,
      left_join: r in Region,
      as: :region,
      on: r.id == cn.region_id,
      where: ^last_record_clause,
      where: ^filter_clause,
      where: ^search_clause,
      order_by: ^order_by_clause,
      select: %{
        id: e.id,
        full_name: u.full_name,
        start_date: u.start_date,
        okta_user_uid: u.okta_user_uid,
        avatar_url: u.avatar_url,
        email: u.email,
        phone: u.phone,
        partner_name: p.name,
        partner_id: p.id,
        client_name: c.name,
        client_id: c.id,
        country_name: cn.name,
        country_iso_three: cn.iso_alpha_3_code,
        country_id: cn.id,
        region_name: r.name,
        sql_row_count: fragment("count(*) over()")
      }
  end

  defp build_last_record_clause(0, _last_value, _sort_column, _sort_direction) do
    dynamic(true)
  end

  defp build_last_record_clause(last_id, last_value, sort_column, sort_direction) do
    cond do
      Enum.member?([:full_name, :start_date], sort_column) ->
        last_record_clause(sort_direction, :user, sort_column, last_id, last_value)

      Enum.member?([:client_name], sort_column) ->
        last_record_clause(sort_direction, :client, sort_column, last_id, last_value)

      Enum.member?([:client_country_name], sort_column) ->
        last_record_clause(sort_direction, :country, sort_column, last_id, last_value)
    end
  end

  defp last_record_clause(sort_direction, table, sort_column, last_id, last_value) do
    if sort_direction == :asc do
      dynamic(
        [{^table, x}],
        field(x, ^sort_column) > ^last_value or
          (field(x, ^sort_column) == ^last_value and x.id > ^last_id)
      )
    else
      dynamic(
        [{^table, x}],
        field(x, ^sort_column) < ^last_value or
          (field(x, ^sort_column) == ^last_value and x.id > ^last_id)
      )
    end
  end

  defp build_order_by_clause(:client_name, sort_direction) do
    [{sort_direction, dynamic([client: c], c.name)}, asc: :id]
  end

  defp build_order_by_clause(:country_name, sort_direction) do
    [{sort_direction, dynamic([country: cn], cn.name)}, asc: :id]
  end

  defp build_order_by_clause(:region_name, sort_direction) do
    [{sort_direction, dynamic([region: r], r.name)}, asc: :id]
  end

  defp build_order_by_clause(:full_name, sort_direction) do
    [{sort_direction, dynamic([user: u], u.full_name)}, asc: :id]
  end

  defp build_order_by_clause(:start_date, sort_direction) do
    [{sort_direction, dynamic([user: u], u.start_date)}, asc: :id]
  end

  defp build_order_by_clause(:partner_name, sort_direction) do
    [{sort_direction, dynamic([partner: p], p.name)}, asc: :id]
  end

  defp build_order_by_clause(sort_column, sort_direction) do
    [{sort_direction, sort_column}, asc: :id]
  end

  defp build_filter_clause(filter_by) do
    Enum.reduce(filter_by, dynamic(true), fn filter, filter_clause ->
      where_clause = build_filter_where_clause(Macro.underscore(filter.name), filter.value)
      dynamic([u, c, a, cn], ^filter_clause and ^where_clause)
    end)
  end

  defp build_filter_where_clause("client_id", value) do
    client_ids = String.split(value, ",")
    dynamic([client: c], c.id in ^client_ids)
  end

  defp build_filter_where_clause("client_name", value) do
    filter_value = "%#{value}%"
    dynamic([client: c], like(c.name, ^filter_value))
  end

  defp build_filter_where_clause("country_id", value) do
    country_ids = String.split(value, ",")
    dynamic([country: cn], cn.id in ^country_ids)
  end

  defp build_filter_where_clause("region_id", value) do
    region_ids = String.split(value, ",")
    dynamic([region: r], r.id in ^region_ids)
  end

  defp build_filter_where_clause("country_name", value) do
    filter_value = "%#{value}%"
    dynamic([country: cn], like(cn.name, ^filter_value))
  end

  defp build_filter_where_clause("partner_id", value) do
    partner_ids = String.split(value, ",")
    dynamic([partner: p], p.id in ^partner_ids)
  end

  defp build_filter_where_clause("full_name", value) do
    filter_value = "%#{value}%"
    dynamic([u, c, a, cn], like(u.full_name, ^filter_value))
  end

  defp build_filter_where_clause("start_date", value) do
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

    dynamic([u, c, a, cn], u.start_date >= ^start_date and u.start_date <= ^end_date)
  end

  defp build_search_clause(search_by) do
    if search_by != nil && String.trim(search_by) != "" do
      search_by_value = "#{String.trim(search_by)}:*"

      dynamic(
        [user: u],
        fragment("to_tsvector(?) @@ plainto_tsquery(?)", u.okta_user_uid, ^search_by_value) or
          fragment("to_tsvector(?) @@ plainto_tsquery(?)", u.full_name, ^search_by_value)
      )
    else
      dynamic(true)
    end
  end
end
