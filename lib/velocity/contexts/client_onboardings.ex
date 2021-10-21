defmodule Velocity.Contexts.ClientOnboardings do
  @moduledoc "context for client_onboardings"

  alias Ecto.Query
  alias Velocity.Contexts.Clients
  alias Velocity.Contexts.Contracts
  alias Velocity.Contexts.Processes
  alias Velocity.Repo
  alias Velocity.Schema.Address
  alias Velocity.Schema.Client
  alias Velocity.Schema.ClientOnboarding
  alias Velocity.Schema.Contract
  alias Velocity.Schema.Country
  alias Velocity.Schema.Employment
  alias Velocity.Schema.Partner
  alias Velocity.Schema.Process
  alias Velocity.Schema.Region
  alias Velocity.Schema.Task
  alias Velocity.Schema.TaskAssignment

  import Ecto.Query

  def get!(_user_id, id) do
    # TODO: restrict data based on roles and/or roles assignments
    Repo.get!(ClientOnboarding, id)
  end

  def get_for_contract(_user_id, contract_id) do
    # TODO: restrict data based on roles and/or roles assignments
    Repo.get_by(ClientOnboarding, contract_id: contract_id)
  end

  def create(params) do
    %ClientOnboarding{}
    |> ClientOnboarding.changeset(params)
    |> Repo.insert()
  end

  @doc """
    This method will perform the following steps:
      - check for and create a client with an identical alternate key does not
        yet exist
      - check for and create a contract for the client if the contract does
        not exist
      - check for an existing client onboarding associated to the client and
        contract 
        - if onboarding does not exist it will create a process from the 
          provided template name
        - create an onboarding record for the contract and process
    The steps above will that multiple calls to this method with the
    same data will not create multiple records for any entity that it touches.
  """
  def start(params) do
    Repo.transaction(fn ->
      # is there a client with the given salesforce id?
      client = Clients.get_client_for_salesforce_id(params[:salesforce_id])

      client =
        if client == nil do
          # nope... so create one
          {:ok, client} =
            Clients.create_client(%{
              name: params[:client_name],
              salesforce_id: params[:salesforce_id]
            })

          client
        else
          client
        end

      # is there a contract for the client?
      contract = Contracts.get_for_client(client.id)

      contract =
        if contract == nil do
          # nope... create the contract
          {:ok, contract} = Contracts.create(%{client_id: client.id})
          contract
        else
          contract
        end

      # is there a client onboarding for the contract? TODO: user?
      client_onboarding = get_for_contract(nil, contract.id)

      client_onboarding =
        if client_onboarding == nil do
          {:ok, process} =
            Processes.create_for_template_name(
              params[:process_template_name],
              params[:service_names]
            )

          {:ok, client_onboarding} = create(%{contract_id: contract.id, process_id: process.id})
          client_onboarding
        else
          client_onboarding
        end

      # ensure process started...
      Processes.start(Repo.get!(Process, client_onboarding.process_id))
      client_onboarding
    end)
  end

  def update(params) do
    Repo.get!(ClientOnboarding, params.id)
    |> ClientOnboarding.changeset(params)
    |> Repo.update()
  end

  def delete(id) do
    %ClientOnboarding{id: id}
    |> Repo.delete()
  end

  def client_onboardings_report(
        page_size,
        sort_column,
        sort_direction,
        last_id,
        last_value,
        filter_by,
        search_by
      ) do
    query =
      client_onboardings_report_query(
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

  def client_onboardings_report_query(
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
      from(e in Employment,
        as: :employment,
        group_by: [e.contract_id, e.partner_id],
        select: %{
          employees: count(e.contract_id),
          contract_id: e.contract_id,
          partner_id: e.partner_id
        }
      )

    from(co in ClientOnboarding,
      as: :client_onboarding,
      left_join: c in Contract,
      as: :contract,
      on: c.id == co.contract_id,
      left_join: c2 in Client,
      as: :client,
      on: c.client_id == c2.id,
      left_join: em in ^subquery(employees),
      as: :employment,
      on: c.id == em.contract_id,
      left_join: p in Partner,
      as: :partner,
      on: p.id == em.partner_id,
      left_join: a in Address,
      as: :address,
      on: c2.address_id == a.id,
      left_join: c3 in Country,
      as: :country,
      on: c3.id == a.country_id,
      left_join: r in Region,
      as: :region,
      on: r.id == c3.region_id,
      left_join: p2 in Process,
      as: :process,
      on: p2.id == co.process_id,
      where: ^last_record_clause,
      where: ^search_clause,
      order_by: ^order_by_clause,
      select: %{
        id: co.id,
        contract_id: c.id,
        process_id: co.process_id,
        client_id: c.client_id,
        full_name: c2.name,
        partner_name: p.name,
        partner_id: p.id,
        region_name: r.name,
        country_name: c3.name,
        percent_complete: p2.percent_complete,
        employees: em.employees,
        sql_row_count: fragment("count(*) over()")
      }
    )
    |> build_filter_join_clause(filter_by)
    |> where(^filter_clause)
  end

  defp build_filter_join_clause(query, filter_by) do
    # join to tasks/task_assignments when csr_user_id filter present
    if Enum.find(filter_by, fn filter -> filter[:name] == "csr_user_id" end) do
      query
      |> join(:inner, [process: p], t in Task, on: t.process_id == p.id, as: :task)
      |> join(:inner, [task: t], ta in TaskAssignment,
        on: ta.task_id == t.id,
        as: :task_assignment
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
      Enum.member?([:full_name], sort_column) ->
        last_record_clause(
          sort_direction,
          :client_onboarding,
          :client,
          :name,
          last_id,
          last_value
        )

      Enum.member?([:partner_name], sort_column) ->
        last_record_clause(
          sort_direction,
          :client_onboarding,
          :partner,
          :name,
          last_id,
          last_value
        )

      Enum.member?([:region_name], sort_column) ->
        last_record_clause(
          sort_direction,
          :client_onboarding,
          :region,
          :name,
          last_id,
          last_value
        )

      Enum.member?([:country_name], sort_column) ->
        last_record_clause(
          sort_direction,
          :client_onboarding,
          :country,
          :name,
          last_id,
          last_value
        )

      Enum.member?([:percent_complete], sort_column) ->
        last_record_clause(
          sort_direction,
          :client_onboarding,
          :process,
          sort_column,
          last_id,
          last_value
        )

      Enum.member?([:employees], sort_column) ->
        last_record_clause(
          sort_direction,
          :client_onboarding,
          :employment,
          sort_column,
          last_id,
          last_value
        )
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

  defp build_order_by_clause(:full_name, sort_direction) do
    [{sort_direction, dynamic([client: c2], c2.name)}, asc: :id]
  end

  defp build_order_by_clause(:employees, sort_direction) do
    [{sort_direction, dynamic([employment: em], em.employees)}, asc: :id]
  end

  defp build_order_by_clause(:country_name, sort_direction) do
    [{sort_direction, dynamic([country: c3], c3.name)}, asc: :id]
  end

  defp build_order_by_clause(:region_name, sort_direction) do
    [{sort_direction, dynamic([region: r], r.name)}, asc: :id]
  end

  defp build_order_by_clause(:partner_name, sort_direction) do
    [{sort_direction, dynamic([partner: p], p.name)}, asc: :id]
  end

  defp build_order_by_clause(:percent_complete, sort_direction) do
    [{sort_direction, dynamic([process: p2], p2.percent_complete)}, asc: :id]
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

  defp build_filter_where_clause("region_id", value) do
    region_ids = String.split(value, ",")
    dynamic([region: r], r.id in ^region_ids)
  end

  defp build_filter_where_clause("country_id", value) do
    country_ids = String.split(value, ",")
    dynamic([country: cn], cn.id in ^country_ids)
  end

  defp build_filter_where_clause("csr_user_id", value) do
    user_ids = String.split(value, ",")
    dynamic([task_assignment: ta], ta.user_id in ^user_ids)
  end

  defp build_filter_where_clause("partner_id", value) do
    partner_ids = String.split(value, ",")
    dynamic([partner: p], p.id in ^partner_ids)
  end

  defp build_search_clause(search_by) do
    if search_by != nil && String.trim(search_by) != "" do
      search_by_value = "#{String.trim(search_by)}:*"

      dynamic(
        [client: c2, contract: c],
        fragment("to_tsvector(CAST(? as text)) @@ plainto_tsquery(?)", c.id, ^search_by_value) or
          fragment("to_tsvector(?) @@ plainto_tsquery(?)", c2.name, ^search_by_value)
      )
    else
      dynamic(true)
    end
  end
end
