defmodule Velocity.Contexts.Contracts do
  @moduledoc "context for contracts"

  alias Ecto.Query
  alias Velocity.Repo
  alias Velocity.Schema.Address
  alias Velocity.Schema.Client
  alias Velocity.Schema.Contract
  alias Velocity.Schema.Country
  alias Velocity.Schema.Employment
  alias Velocity.Schema.Region

  import Ecto.Query

  def get!(id) do
    Repo.get!(Contract, id)
  end

  def get_for_client(client_id) do
    Repo.get_by(Contract, client_id: client_id)
  end

  def create(params) do
    %Contract{}
    |> Contract.changeset(params)
    |> Repo.insert()
  end

  def update(params) do
    Repo.get!(Contract, params.id)
    |> Contract.changeset(params)
    |> Repo.update()
  end

  def delete(id) do
    %Contract{id: id}
    |> Repo.delete()
  end

  def paginated_client_contracts_report(
        page_size,
        sort_column,
        sort_direction,
        last_id,
        last_value,
        filter_by,
        search_by
      ) do
    client_contracts_report_query(
      sort_column,
      sort_direction,
      last_id,
      last_value,
      filter_by,
      search_by
    )
    |> Query.limit(^page_size)
    |> Repo.all()
  end

  defp client_contracts_report_query(
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

    employees =
      from(em in Employment,
        as: :employment,
        left_join: c in Country,
        on: c.id == em.country_id,
        group_by: em.contract_id,
        select: %{
          contract_id: em.contract_id,
          total_employees: count(em.contract_id),
          active_employees:
            fragment(
              "sum(case when ? is not null and ? is null then 1 else 0 end)",
              em.effective_date,
              em.end_date
            ),
          operating_countries: fragment("string_agg(?, ?)", c.name, ", ")
        }
      )

    from(c in Contract,
      as: :contract,
      left_join: c1 in Client,
      as: :client,
      on: c.client_id == c1.id,
      left_join: em in ^subquery(employees),
      as: :employment,
      on: em.contract_id == c.id,
      left_join: a in Address,
      as: :address,
      on: a.id == c1.address_id,
      left_join: c2 in Country,
      as: :country,
      on: c2.id == a.country_id,
      left_join: r in Region,
      as: :region,
      on: r.id == c2.region_id,
      where: ^last_record_clause,
      where: ^filter_clause,
      where: ^search_clause,
      order_by: ^order_by_clause,
      select: %{
        id: c.id,
        client_name: c1.name,
        region_name: r.name,
        operating_countries: em.operating_countries,
        total_employees: em.total_employees,
        active_employees: em.active_employees,
        sql_row_count: fragment("count(*) over()")
      }
    )
    |> build_operating_countries_filter_join_clause(filter_by)
    |> build_partners_filter_join_clause(filter_by)
  end

  defp build_last_record_clause(0, _last_value, _sort_column, _sort_direction) do
    dynamic(true)
  end

  defp build_last_record_clause(last_id, last_value, sort_column, sort_direction) do
    cond do
      Enum.member?([:client_name], sort_column) ->
        last_record_clause(sort_direction, :contract, :client, :name, last_id, last_value)

      Enum.member?([:region_name], sort_column) ->
        last_record_clause(sort_direction, :contract, :region, :name, last_id, last_value)
    end
  end

  defp last_record_clause(sort_direction, primary, table, sort_column, last_id, last_value) do
    if sort_direction == :asc do
      dynamic(
        [{^primary, p}, {^table, x}],
        field(x, ^sort_column) > ^last_value or
          (field(x, ^sort_column) == ^last_value and p.id > ^last_id)
      )
    else
      dynamic(
        [{^primary, p}, {^table, x}],
        field(x, ^sort_column) < ^last_value or
          (field(x, ^sort_column) == ^last_value and p.id > ^last_id)
      )
    end
  end

  defp build_order_by_clause(:client_name, sort_direction) do
    [{sort_direction, dynamic([client: c1], c1.name)}, asc: :id]
  end

  defp build_order_by_clause(:region_name, sort_direction) do
    [{sort_direction, dynamic([region: r], r.name)}, asc: :id]
  end

  defp build_filter_clause(filter_by) do
    Enum.reduce(filter_by, dynamic(true), fn filter, filter_clause ->
      where_clause = build_filter_where_clause(Macro.underscore(filter.name), filter.value)
      dynamic([], ^filter_clause and ^where_clause)
    end)
  end

  defp build_filter_where_clause("region_id", value) do
    region_ids = String.split(value, ",")
    dynamic([region: r], r.id in ^region_ids)
  end

  defp build_filter_where_clause("country_id", _value) do
    dynamic(true)
  end

  defp build_filter_where_clause("partner_id", _value) do
    dynamic(true)
  end

  defp build_operating_countries_filter_join_clause(query, filter_by) do
    filter = Enum.find(filter_by, fn filter -> Macro.underscore(filter.name) == "country_id" end)

    if filter do
      country_ids = String.split(filter.value, ",")

      countries_query =
        from(em in Employment,
          where: em.country_id in ^country_ids,
          distinct: em.contract_id,
          select: %{contract_id: em.contract_id}
        )

      join(query, :inner, [contract: c], c3 in ^subquery(countries_query),
        on: c.id == c3.contract_id
      )
    else
      query
    end
  end

  defp build_partners_filter_join_clause(query, filter_by) do
    filter = Enum.find(filter_by, fn filter -> Macro.underscore(filter.name) == "partner_id" end)

    if filter do
      partner_ids = String.split(filter.value, ",")

      partners_query =
        from(em in Employment,
          where: em.partner_id in ^partner_ids,
          distinct: em.contract_id,
          select: %{contract_id: em.contract_id}
        )

      join(query, :inner, [contract: c], c3 in ^subquery(partners_query),
        on: c.id == c3.contract_id
      )
    else
      query
    end
  end

  defp build_search_clause(search_by) do
    if search_by != nil && String.trim(search_by) != "" do
      search_by_value = "#{String.trim(search_by)}:*"

      dynamic(
        [client: c1, contract: c],
        fragment("to_tsvector(CAST(? as text)) @@ plainto_tsquery(?)", c.id, ^search_by_value) or
          fragment("to_tsvector(?) @@ plainto_tsquery(?)", c1.name, ^search_by_value)
      )
    else
      dynamic(true)
    end
  end
end
