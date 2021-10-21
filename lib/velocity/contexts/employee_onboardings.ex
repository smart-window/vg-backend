defmodule Velocity.Contexts.EmployeeOnboardings do
  @moduledoc "context for employee_onboardings"

  alias Ecto.Query
  alias Velocity.Contexts.Clients
  alias Velocity.Contexts.Contracts
  alias Velocity.Contexts.Employees
  alias Velocity.Contexts.Employments
  alias Velocity.Contexts.Jobs
  alias Velocity.Contexts.Processes
  alias Velocity.Contexts.Users
  alias Velocity.Repo
  alias Velocity.Schema.Client
  alias Velocity.Schema.Contract
  alias Velocity.Schema.Country
  alias Velocity.Schema.Employee
  alias Velocity.Schema.EmployeeOnboarding
  alias Velocity.Schema.Employment
  alias Velocity.Schema.Partner
  alias Velocity.Schema.Process
  alias Velocity.Schema.Region
  alias Velocity.Schema.Task
  alias Velocity.Schema.TaskAssignment
  alias Velocity.Schema.User

  import Ecto.Query

  def get!(_user_id, id) do
    # TODO: restrict data based on roles and/or roles assignments
    Repo.get!(EmployeeOnboarding, id)
  end

  def get_for_employment(employment_id) do
    Repo.get_by(EmployeeOnboarding, employment_id: employment_id)
  end

  def create(params) do
    %EmployeeOnboarding{}
    |> EmployeeOnboarding.changeset(params)
    |> Repo.insert()
  end

  @doc """
    This method will perform the following steps:
      - check for an employment matching the input salesforce_id
        - if no employment exists
          - find partner (from partner_name)
          - find country of employment (from country_code/iso_alpha_3_code)
          - create user record for the email (from email) - what about okta_user_uid?
          - create employee record using user
          - create contract record
          - create job record
          - create employment record
      - check for an existing employee onboarding associated to the client and
        employment contract 
        - if onboarding does not exist it will create a process from the 
          provided template name
        - create an employee onboarding record for the employment and process
    The steps above will ensure that multiple calls to this method with the
    same data will not create multiple records for any entity that it touches.
  """
  def start(params) do
    Repo.transaction(fn ->
      client = Clients.get_client!(params[:client_id])
      # is there an existing employment for the salesforce opportunity?
      salesforce_id = params[:salesforce_id]
      employment = Repo.get_by(Employment, salesforce_id: salesforce_id)

      employment =
        if employment == nil do
          # nope... ensure partner and country
          partner = Repo.get_by!(Partner, name: params[:partner])
          country_code = params[:country_code]

          country =
            Repo.one!(
              from c in Country,
                where:
                  c.iso_alpha_3_code == ^country_code or c.iso_alpha_2_code == ^country_code or
                    c.name == ^country_code
            )

          nationality_id =
            if Map.has_key?(params, :nationality_code) &&
                 String.length(params[:nationality_code]) > 0 do
              nationality_code = params[:nationality_code]

              nationality =
                Repo.one(
                  from c in Country,
                    where:
                      c.iso_alpha_3_code == ^nationality_code or
                        c.iso_alpha_2_code == ^nationality_code or c.name == ^nationality_code
                )

              nationality.id
            else
              nil
            end

          {:ok, user} =
            Users.create(%{
              first_name: params[:first_name],
              last_name: params[:last_name],
              full_name: params[:first_name] <> " " <> params[:last_name],
              nationality_id: nationality_id,
              email: params[:email],
              okta_user_uid: params[:email]
            })

          {:ok, employee} = Employees.create(%{user_id: user.id})
          {:ok, contract} = Contracts.create(%{client_id: client.id})
          {:ok, job} = Jobs.create(%{client_id: client.id, title: params[:job_title]})

          {:ok, employment} =
            Employments.create(%{
              salesforce_id: salesforce_id,
              partner_id: partner.id,
              employee_id: employee.id,
              job_id: job.id,
              contract_id: contract.id,
              country_id: country.id,
              anticipated_start_date: params[:anticipated_start_date]
            })

          employment
        else
          employment
        end

      # is there an employee onboarding for the employment?
      employee_onboarding = get_for_employment(employment.id)

      employee_onboarding =
        if employee_onboarding == nil do
          {:ok, process} =
            Processes.create_for_template_name(
              params[:process_template_name],
              params[:service_names]
            )

          {:ok, employee_onboarding} =
            create(%{employment_id: employment.id, process_id: process.id})

          employee_onboarding
        else
          employee_onboarding
        end

      # ensure process started...
      # Processes.start(Repo.get!(Process, client_onboarding.process_id))
      employee_onboarding
    end)
  end

  def update(params) do
    Repo.get!(EmployeeOnboarding, params.id)
    |> EmployeeOnboarding.changeset(params)
    |> Repo.update()
  end

  def delete(id) do
    %EmployeeOnboarding{id: id}
    |> Repo.delete()
  end

  def get_employment_for_process(process_id) do
    Repo.one(
      from emp in Employment,
        join: eo in assoc(emp, :employee_onboardings),
        where: eo.process_id == ^process_id,
        preload: [:employee, :contract, :job]
    )
  end

  def get_all(
        page_size,
        sort_column,
        sort_direction,
        last_id,
        last_value,
        filter_by,
        search_by
      ) do
    query =
      employees_query(
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

  def employees_query(
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

    from(eo in EmployeeOnboarding,
      as: :employment_onboarding,
      join: em in Employment,
      as: :employment,
      on: em.id == eo.employment_id,
      join: ctr in Contract,
      as: :contract,
      on: ctr.id == em.contract_id,
      join: p in Partner,
      as: :partner,
      on: em.partner_id == p.id,
      join: e in Employee,
      as: :employee,
      on: em.employee_id == e.id,
      join: u in User,
      on: u.id == e.user_id,
      as: :user,
      join: c in Client,
      as: :client,
      on: c.id == ctr.client_id,
      join: cn in Country,
      as: :country,
      on: cn.id == em.country_id,
      join: r in Region,
      as: :region,
      on: r.id == cn.region_id,
      join: prc in Process,
      as: :process,
      on: prc.id == eo.process_id,
      where: ^last_record_clause,
      where: ^search_clause,
      order_by: ^order_by_clause,
      select: %{
        id: eo.id,
        contract_id: ctr.id,
        employment_id: em.id,
        process_id: prc.id,
        full_name: u.full_name,
        partner_name: p.name,
        client_name: c.name,
        region_name: r.name,
        country_name: cn.name,
        percent_complete: prc.percent_complete,
        benefits: eo.benefits,
        immigration: eo.immigration,
        signature_status: eo.signature_status,
        anticipated_start_date: em.anticipated_start_date,
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
      Enum.member?([:full_name, :start_date], sort_column) ->
        last_record_clause(
          sort_direction,
          :employment_onboarding,
          :user,
          sort_column,
          last_id,
          last_value
        )

      Enum.member?([:partner_name], sort_column) ->
        last_record_clause(
          sort_direction,
          :employment_onboarding,
          :partner,
          :name,
          last_id,
          last_value
        )

      Enum.member?([:region_name], sort_column) ->
        last_record_clause(
          sort_direction,
          :employment_onboarding,
          :region,
          :name,
          last_id,
          last_value
        )

      Enum.member?([:country_name], sort_column) ->
        last_record_clause(
          sort_direction,
          :employment_onboarding,
          :country,
          :name,
          last_id,
          last_value
        )

      Enum.member?([:percent_complete], sort_column) ->
        last_record_clause(
          sort_direction,
          :employment_onboarding,
          :process,
          sort_column,
          last_id,
          last_value
        )

      Enum.member?([:benefits], sort_column) ->
        last_record_clause(
          sort_direction,
          :employment_onboarding,
          :employment_onboarding,
          :benefits,
          last_id,
          last_value
        )

      Enum.member?([:immigration], sort_column) ->
        last_record_clause(
          sort_direction,
          :employment_onboarding,
          :employment_onboarding,
          :immigration,
          last_id,
          last_value
        )

      Enum.member?([:anticipated_start_date], sort_column) ->
        last_record_clause(
          sort_direction,
          :employment_onboarding,
          :employment,
          :anticipated_start_date,
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

  defp build_order_by_clause(:partner_name, sort_direction) do
    [{sort_direction, dynamic([partner: p], p.name)}, asc: :id]
  end

  defp build_order_by_clause(:percent_complete, sort_direction) do
    [{sort_direction, dynamic([process: prc], prc.percent_complete)}, asc: :id]
  end

  defp build_order_by_clause(:signature_status, sort_direction) do
    [{sort_direction, dynamic([employment_onboarding: eo], eo.signature_status)}, asc: :id]
  end

  defp build_order_by_clause(:immigration, sort_direction) do
    [{sort_direction, dynamic([employment_onboarding: eo], eo.immigration)}, asc: :id]
  end

  defp build_order_by_clause(:benefits, sort_direction) do
    [{sort_direction, dynamic([employment_onboarding: eo], eo.benefits)}, asc: :id]
  end

  defp build_order_by_clause(:anticipated_start_date, sort_direction) do
    [{sort_direction, dynamic([employment: em], em.anticipated_start_date)}, asc: :id]
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
        [user: u, contract: ctr],
        fragment("to_tsvector(CAST(? as text)) @@ plainto_tsquery(?)", ctr.id, ^search_by_value) or
          fragment("to_tsvector(?) @@ plainto_tsquery(?)", u.full_name, ^search_by_value)
      )
    else
      dynamic(true)
    end
  end
end
