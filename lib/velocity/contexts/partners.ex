defmodule Velocity.Contexts.Partners do
  @moduledoc "context for partners"

  alias Ecto.Query
  alias Velocity.Repo
  alias Velocity.Schema.Address
  alias Velocity.Schema.Country
  alias Velocity.Schema.Employment
  alias Velocity.Schema.Partner
  alias Velocity.Schema.PartnerOperatingCountry
  alias Velocity.Schema.Region

  import Ecto.Query

  import Ecto.Query

  def get!(id) do
    Repo.get!(Partner, id)
  end

  def create(params) do
    %Partner{}
    |> Partner.changeset(params)
    |> Repo.insert()
  end

  def update(params) do
    Repo.get!(Partner, params.id)
    |> Partner.changeset(params)
    |> Repo.update()
  end

  def delete(id) do
    %Partner{id: id}
    |> Repo.delete()
  end

  def all do
    Repo.all(from p in Partner, order_by: :name)
  end

  def paginated_partners_report(
        page_size,
        sort_column,
        sort_direction,
        last_id,
        last_value,
        filter_by,
        search_by
      ) do
    partners_report_query(
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

  defp partners_report_query(
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

    employments =
      from(employment in Employment,
        as: :employment,
        left_join: partner in Partner,
        on: partner.id == employment.partner_id,
        group_by: partner.id,
        select: %{
          partner_id: partner.id,
          total_employees: count(employment.employee_id),
          active_employees:
            fragment(
              "sum(case when ? is not null and ? is null then 1 else 0 end)",
              employment.effective_date,
              employment.end_date
            )
        }
      )

    from(partner in Partner,
      as: :partner,
      left_join: address in Address,
      as: :address,
      on: address.id == partner.address_id,
      left_join: country in Country,
      as: :country,
      on: country.id == address.country_id,
      left_join: region in Region,
      as: :region,
      on: region.id == country.region_id,
      left_join: employment in ^subquery(employments),
      as: :employment,
      on: employment.partner_id == partner.id,
      left_join: operating_country in PartnerOperatingCountry,
      as: :operating_country,
      on: operating_country.partner_id == partner.id,
      where: ^last_record_clause,
      where: ^filter_clause,
      where: ^search_clause,
      order_by: ^order_by_clause,
      distinct: partner.id,
      select: %{
        id: partner.id,
        partner_name: partner.name,
        region_name: region.name,
        total_employees: employment.total_employees,
        active_employees: employment.active_employees,
        sql_row_count: fragment("count(*) over()")
      }
    )
  end

  defp build_last_record_clause(0, _last_value, _sort_column, _sort_direction) do
    dynamic(true)
  end

  defp build_last_record_clause(last_id, last_value, sort_column, sort_direction) do
    cond do
      Enum.member?([:partner_name], sort_column) ->
        last_record_clause(sort_direction, :contract, :partner, :name, last_id, last_value)

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

  defp build_order_by_clause(:partner_name, sort_direction) do
    [{sort_direction, dynamic([partner: c1], c1.name)}, asc: :id]
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

  defp build_filter_where_clause("country_id", value) do
    country_ids = String.split(value, ",")
    dynamic([operating_country: oc], oc.country_id in ^country_ids)
  end

  defp build_search_clause(search_by) do
    if search_by != nil && String.trim(search_by) != "" do
      search_by_value = "#{String.trim(search_by)}:*"

      dynamic(
        [partner: c],
        fragment("to_tsvector(CAST(? as text)) @@ plainto_tsquery(?)", c.id, ^search_by_value) or
          fragment("to_tsvector(?) @@ plainto_tsquery(?)", c.name, ^search_by_value)
      )
    else
      dynamic(true)
    end
  end
end
