defmodule Velocity.Contexts.Clients do
  @moduledoc """
  The Contexts.Clients context.
  """

  alias Ecto.Query
  alias Velocity.Repo
  alias Velocity.Schema.Address
  alias Velocity.Schema.Client
  alias Velocity.Schema.ClientOperatingCountry
  alias Velocity.Schema.Contract
  alias Velocity.Schema.Country
  alias Velocity.Schema.Employment
  alias Velocity.Schema.Region

  import Ecto.Query

  @doc """
  Returns the list of clients.

  ## Examples

      iex> list_clients()
      [%Client{}, ...]

  """
  def list_clients do
    Repo.all(from c in Client, order_by: :name)
  end

  @doc """
  Gets a single client.

  Raises if the Client does not exist.

  ## Examples

      iex> get_client!(123)
      %Client{}

  """
  def get_client!(id), do: Repo.get!(Client, id)

  @doc """
  Gets a single client by name.

  ## Examples

      iex> get_client_for_name("Fubar")
      %Client{}

  """
  def get_client_for_name(name), do: Repo.get_by(Client, name: name)

  @doc """
  Gets a single client by salesforce id.

  ## Examples

      iex> get_client_for_salesforce_id("the salesforce id")
      %Client{}

  """
  def get_client_for_salesforce_id(salesforce_id),
    do: Repo.get_by(Client, salesforce_id: salesforce_id)

  @doc """
  Creates a client.

  ## Examples

      iex> create_client(%{field: value})
      {:ok, %Client{}}

      iex> create_client(%{field: bad_value})
      {:error, ...}

  """
  def create_client(attrs \\ %{}) do
    %Client{}
    |> Client.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a client.

  ## Examples

      iex> update_client(client, %{field: new_value})
      {:ok, %Client{}}

      iex> update_client(client, %{field: bad_value})
      {:error, ...}

  """
  def update_client(id, attrs) do
    Repo.get!(Client, id)
    |> Client.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Client.

  ## Examples

      iex> delete_client(client)
      {:ok, %Client{}}

      iex> delete_client(client)
      {:error, ...}

  """
  def delete_client(id) do
    %Client{id: id}
    |> Repo.delete()
  end

  @doc """
  Returns a data structure for tracking client changes.

  ## Examples

      iex> change_client(client)
      %Todo{...}

  """
  def change_client(client = %Client{}, attrs \\ %{}) do
    Client.changeset(client, attrs)
  end

  def update_client(args) do
    Repo.get!(Client, args.id)
    |> Client.changeset(args)
    |> Repo.update()
  end

  def get_by(keyword) do
    Repo.get_by(Client, keyword)
  end

  def get_teams(id) do
    client =
      Client
      |> Repo.get(id)
      |> Repo.preload(:teams)

    Enum.map(client.client_teams, fn client_team -> client_team.team end)
  end

  def update_client_general(params) do
    Repo.get!(Client, params.id)
    |> Client.changeset(params)
    |> Repo.update()
  end

  def update_client_goals(params) do
    Repo.get!(Client, params.id)
    |> Client.changeset(params)
    |> Repo.update()
  end

  def update_client_interaction_notes(params) do
    Repo.get!(Client, params.id)
    |> Client.changeset(params)
    |> Repo.update()
  end

  def update_client_referral_information(params) do
    Repo.get!(Client, params.id)
    |> Client.changeset(params)
    |> Repo.update()
  end

  def update_client_payments_and_pricing(params) do
    Repo.get!(Client, params.id)
    |> Client.changeset(params)
    |> Repo.update()
  end

  def paginated_clients_report(
        page_size,
        sort_column,
        sort_direction,
        last_id,
        last_value,
        filter_by,
        search_by
      ) do
    clients_report_query(
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

  defp clients_report_query(
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
        left_join: contract in Contract,
        on: contract.id == employment.contract_id,
        left_join: client in Client,
        on: client.id == contract.client_id,
        group_by: client.id,
        select: %{
          client_id: client.id,
          total_employees: count(employment.employee_id),
          active_employees:
            fragment(
              "sum(case when ? is not null and ? is null then 1 else 0 end)",
              employment.effective_date,
              employment.end_date
            )
        }
      )

    from(client in Client,
      as: :client,
      left_join: address in Address,
      as: :address,
      on: address.id == client.address_id,
      left_join: country in Country,
      as: :country,
      on: country.id == address.country_id,
      left_join: region in Region,
      as: :region,
      on: region.id == country.region_id,
      left_join: employment in ^subquery(employments),
      as: :employment,
      on: employment.client_id == client.id,
      left_join: operating_country in ClientOperatingCountry,
      as: :operating_country,
      on: operating_country.client_id == client.id,
      where: ^last_record_clause,
      where: ^filter_clause,
      where: ^search_clause,
      order_by: ^order_by_clause,
      distinct: client.id,
      select: %{
        id: client.id,
        client_name: client.name,
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
      Enum.member?([:client_name], sort_column) ->
        last_record_clause(sort_direction, :client, :client, :name, last_id, last_value)

      Enum.member?([:region_name], sort_column) ->
        last_record_clause(sort_direction, :client, :region, :name, last_id, last_value)
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

  defp build_filter_where_clause("country_id", value) do
    country_ids = String.split(value, ",")
    dynamic([operating_country: oc], oc.country_id in ^country_ids)
  end

  defp build_search_clause(search_by) do
    if search_by != nil && String.trim(search_by) != "" do
      search_by_value = "#{String.trim(search_by)}:*"

      dynamic(
        [client: c],
        fragment("to_tsvector(CAST(? as text)) @@ plainto_tsquery(?)", c.id, ^search_by_value) or
          fragment("to_tsvector(?) @@ plainto_tsquery(?)", c.name, ^search_by_value)
      )
    else
      dynamic(true)
    end
  end
end
