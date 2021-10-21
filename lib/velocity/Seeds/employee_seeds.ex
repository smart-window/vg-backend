defmodule Velocity.Seeds.EmployeeSeeds do
  alias Velocity.Repo
  alias Velocity.Schema.Address
  alias Velocity.Schema.Client
  alias Velocity.Schema.Contract
  alias Velocity.Schema.Country
  alias Velocity.Schema.Employee
  alias Velocity.Schema.Employment
  alias Velocity.Schema.Job
  alias Velocity.Schema.Partner
  alias Velocity.Schema.User

  def create do
    countries = Repo.all(Country)

    # Create Addresses
    addresses =
      Enum.map(1..20, fn _ ->
        Repo.insert!(%Address{
          line_1:
            "#{Enum.random(1000..5000)} #{Enum.random(["W", "S", "N", "E"])} Something Street",
          line_2: "",
          line_3: "",
          city: "Puyallup",
          postal_code: "#{Enum.random(80000..99999)}",
          county_district: "Pierce",
          state_province: "WA",
          state_province_iso_alpha_2_code: "",
          timezone: "",
          country_id: Enum.random(countries).id
        })
      end)

    # Create Partners
    partners =
      Enum.map(1..10, fn index ->
        Repo.insert!(%Partner{
          name: "Partner #{index}",
          netsuite_id: "#{Enum.random(1000..3000)}",
          statement_of_work_with: "",
          deployment_agreement_with: "",
          contact_guidelines: "",
          address_id: Enum.random(addresses).id
        })
      end)

    # Create Clients
    clients =
      Enum.map(1..10, fn index ->
        Repo.insert!(%Client{
          name: "Client #{index}"
        })
      end)

    # Create Contracts
    contracts =
      Enum.map(1..200, fn _ ->
        Repo.insert!(%Contract{
          client_id: Enum.random(clients).id
        })
      end)

    # Create Jobs
    jobs =
      Enum.map(1..200, fn index ->
        Repo.insert!(%Job{
          title: "Job Title #{index}",
          client_id: Enum.random(clients).id
        })
      end)

    # Create Users
    users =
      Enum.map(1..200, fn index ->
        first_name = Faker.Person.first_name()
        last_name = Faker.Person.last_name()

        Repo.insert!(%User{
          first_name: first_name,
          last_name: last_name,
          full_name: "#{first_name} #{last_name}",
          email: "email#{index}@company.com",
          okta_user_uid: "asdf-#{index}",
          avatar_url: "",
          timezone: "",
          birth_date: DateTime.to_date(DateTime.utc_now()),
          gender: "",
          marital_status: "",
          visa_work_permit_required: false,
          start_date: DateTime.to_date(DateTime.utc_now()),
          settings: nil,
          country_specific_fields: nil,
          preferred_first_name: "",
          phone: "",
          business_email: "",
          personal_email: "",
          emergency_contact_name: "",
          emergency_contact_relationship: "",
          emergency_contact_phone: "",
          client_id: Enum.random(clients).id
        })
      end)

    # Create Employees
    employees =
      Enum.map(users, fn user ->
        Repo.insert!(%Employee{
          user_id: user.id
        })
      end)

    # Create Employments
    Enum.map(employees, fn employee ->
      Repo.insert!(%Employment{
        effective_date: DateTime.to_date(DateTime.utc_now()),
        partner_id: Enum.random(partners).id,
        employee_id: employee.id,
        job_id: Enum.random(jobs).id,
        contract_id: Enum.random(contracts).id,
        country_id: Enum.random(countries).id
      })
    end)
  end
end
