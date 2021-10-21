defmodule Velocity.Contexts.Employments do
  @moduledoc "context for employments"

  import Ecto.Query

  alias Velocity.Repo
  alias Velocity.Schema.Client
  alias Velocity.Schema.Contract
  alias Velocity.Schema.Country
  alias Velocity.Schema.Employee
  alias Velocity.Schema.Employment
  alias Velocity.Schema.Job
  alias Velocity.Schema.Partner
  alias Velocity.Schema.Region
  alias Velocity.Schema.User

  import Ecto.Query

  def get!(id) do
    Repo.get!(Employment, id)
  end

  def get_by(keyword) do
    Repo.get_by(Employments, keyword)
  end

  def get_for_user(user_id) do
    Repo.one(
      from(e in Employment,
        join: ee in Employee,
        on: ee.id == e.employee_id,
        join: u in User,
        on: u.id == ee.user_id and ee.user_id == ^user_id,
        where: is_nil(e.end_date)
      )
    )
  end

  def get_for_user(employment_id, user_id) do
    employments_query =
      from(emp in Employment,
        join: e in Employee,
        on: emp.employee_id == e.id,
        where: emp.id == ^employment_id and e.user_id == ^user_id
      )

    Repo.one(employments_query)
  end

  def get_current_for_user(user_id) do
    employments_query =
      from(emp in Employment,
        join: e in Employee,
        on: emp.employee_id == e.id,
        where: e.user_id == ^user_id,
        order_by: [desc: emp.effective_date]
      )

    # TODO: handle multiple active employments
    Repo.one(employments_query)
  end

  def create(params) do
    %Employment{}
    |> Employment.changeset(params)
    |> Repo.insert()
  end

  def find_or_create_for_pto_simulation(user, effective_date) do
    {:ok, fake_client} =
      Client.changeset(%Client{}, %{name: "fake-client-#{user.id}"}) |> Repo.insert()

    {:ok, fake_partner} =
      Partner.changeset(%Partner{}, %{name: "fake-partner-#{user.id}"}) |> Repo.insert()

    {:ok, fake_employee} = Employee.changeset(%Employee{}, %{user_id: user.id}) |> Repo.insert()

    {:ok, fake_job} =
      Job.changeset(%Job{}, %{client_id: fake_client.id, title: "fake-job-#{user.id}"})
      |> Repo.insert()

    {:ok, fake_contract} =
      Contract.changeset(%Contract{}, %{client_id: fake_client.id}) |> Repo.insert()

    {:ok, fake_region} =
      Region.changeset(%Region{}, %{name: "fake-region-#{user.id}"}) |> Repo.insert()

    {:ok, fake_country} =
      Country.changeset(%Country{}, %{
        iso_alpha_2_code: "ZZ",
        name: "fake-country-#{user.id}",
        region_id: fake_region.id
      })
      |> Repo.insert()

    Employment.changeset(%Employment{}, %{
      partner_id: fake_partner.id,
      employee_id: fake_employee.id,
      job_id: fake_job.id,
      contract_id: fake_contract.id,
      country_id: fake_country.id,
      effective_date: effective_date
    })
    |> Repo.insert()
  end

  def update(params) do
    Repo.get!(Employment, params.id)
    |> Employment.changeset(params)
    |> Repo.update()
  end

  def delete(id) do
    %Employment{id: id}
    |> Repo.delete()
  end
end
