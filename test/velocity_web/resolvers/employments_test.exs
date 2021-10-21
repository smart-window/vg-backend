defmodule VelocityWeb.Resolvers.EmploymentsTest do
  use VelocityWeb.ConnCase, async: true

  alias Velocity.Repo
  alias Velocity.Schema.Employment

  @get_employment_query """
    query($id: ID!) {
      employment(id: $id) {
        id
        effective_date
        partner {
          id
        }
        employee {
          id
        }
        job {
          id
        }
        contract {
          id
        }
        country {
          id
        }
      }
    }
  """

  @create_employment_mutation """
    mutation CreateEmployment($partner_id: ID!, $employee_id: ID!, $job_id: ID!, $contract_id: ID!, $country_id: ID!, $effective_date: Date!) {
      createEmployment(partner_id: $partner_id, employee_id: $employee_id, job_id: $job_id, contract_id: $contract_id, country_id: $country_id, effective_date: $effective_date) {
        id
        effective_date
        partner {
          id
        }
        employee {
          id
        }
        job {
          id
        }
        contract {
          id
        }
        country {
          id
        }
      }
    }
  """

  @update_employment_mutation """
    mutation UpdateEmployment($id: ID!, $effective_date: Date!) {
      updateEmployment(id: $id, effective_date: $effective_date) {
        id
        effective_date
        partner {
          id
        }
        employee {
          id
        }
        job {
          id
        }
        contract {
          id
        }
        country {
          id
        }
      }
    }
  """

  @delete_employment_mutation """
    mutation DeleteEmployment($id: ID!) {
      deleteEmployment(id: $id) {
        id
      }
    }
  """

  def setup_user do
    country = Factory.insert(:country)
    address = Factory.insert(:address, %{country_id: country.id})

    Factory.insert(:user, %{
      avatar_url: "http://old.url",
      work_address_id: address.id
    })
  end

  def setup_admin_user do
    country = Factory.insert(:country)
    address = Factory.insert(:address, %{country_id: country.id})

    admin_user = Factory.insert(:user, %{work_address_id: address.id})
    admin_group = Factory.insert(:group, %{slug: "admin", okta_group_slug: "PegaAdmins"})
    Factory.insert(:user_group, %{user_id: admin_user.id, group_id: admin_group.id})

    admin_user
  end

  describe "query :employments" do
    test "it gets a employment", %{conn: conn} do
      user = setup_user()

      client = Factory.insert(:client)
      partner = Factory.insert(:partner)

      employee =
        Factory.insert(:employee, %{
          user: user
        })

      job =
        Factory.insert(:job, %{
          client: client
        })

      contract =
        Factory.insert(:contract, %{
          client: client
        })

      country = Factory.insert(:country)

      employment =
        Factory.insert(:employment, %{
          partner: partner,
          employee: employee,
          job: job,
          contract: contract,
          country: country,
          effective_date: "2021-03-24"
        })

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @get_employment_query,
          variables: %{
            id: employment.id
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "employment" => %{
                   "id" => employment_id,
                   "partner" => %{
                     "id" => partner_id
                   },
                   "employee" => %{
                     "id" => employee_id
                   },
                   "job" => %{
                     "id" => job_id
                   },
                   "contract" => %{
                     "id" => contract_id
                   },
                   "country" => %{
                     "id" => country_id
                   },
                   "effective_date" => "2021-03-24"
                 }
               }
             } = response

      assert String.to_integer(employment_id) == employment.id
      assert String.to_integer(partner_id) == partner.id
      assert String.to_integer(employee_id) == employee.id
      assert String.to_integer(job_id) == job.id
      assert String.to_integer(contract_id) == contract.id
      assert String.to_integer(country_id) == country.id
    end
  end

  describe "mutation :employments" do
    test "it creates an employment", %{conn: conn} do
      user = setup_admin_user()

      client = Factory.insert(:client)
      partner = Factory.insert(:partner)

      employee =
        Factory.insert(:employee, %{
          user: user
        })

      job =
        Factory.insert(:job, %{
          client: client
        })

      contract =
        Factory.insert(:contract, %{
          client: client
        })

      country = Factory.insert(:country)

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @create_employment_mutation,
          variables: %{
            partner_id: partner.id,
            employee_id: employee.id,
            job_id: job.id,
            contract_id: contract.id,
            country_id: country.id,
            effective_date: "2021-03-24"
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "createEmployment" => %{
                   "id" => employment_id,
                   "partner" => %{
                     "id" => partner_id
                   },
                   "employee" => %{
                     "id" => employee_id
                   },
                   "job" => %{
                     "id" => job_id
                   },
                   "contract" => %{
                     "id" => contract_id
                   },
                   "country" => %{
                     "id" => country_id
                   },
                   "effective_date" => "2021-03-24"
                 }
               }
             } = response

      assert String.to_integer(partner_id) == partner.id
      assert String.to_integer(employee_id) == employee.id
      assert String.to_integer(job_id) == job.id
      assert String.to_integer(contract_id) == contract.id
      assert String.to_integer(country_id) == country.id
      assert Repo.get(Employment, employment_id)
    end

    test "it updates an existing employment", %{conn: conn} do
      user = setup_admin_user()

      client = Factory.insert(:client)
      partner = Factory.insert(:partner)

      employee =
        Factory.insert(:employee, %{
          user: user
        })

      job =
        Factory.insert(:job, %{
          client: client
        })

      contract =
        Factory.insert(:contract, %{
          client: client
        })

      country = Factory.insert(:country)

      employment =
        Factory.insert(:employment, %{
          partner: partner,
          employee: employee,
          job: job,
          contract: contract,
          country: country,
          effective_date: "2021-03-24"
        })

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @update_employment_mutation,
          variables: %{
            id: employment.id,
            effective_date: "2021-04-01"
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "updateEmployment" => %{
                   "id" => employment_id,
                   "partner" => %{
                     "id" => partner_id
                   },
                   "employee" => %{
                     "id" => employee_id
                   },
                   "job" => %{
                     "id" => job_id
                   },
                   "contract" => %{
                     "id" => contract_id
                   },
                   "country" => %{
                     "id" => country_id
                   },
                   "effective_date" => "2021-04-01"
                 }
               }
             } = response

      assert String.to_integer(employment_id) == employment.id
      assert String.to_integer(partner_id) == partner.id
      assert String.to_integer(employee_id) == employee.id
      assert String.to_integer(job_id) == job.id
      assert String.to_integer(contract_id) == contract.id
      assert String.to_integer(country_id) == country.id
    end

    test "it returns an error on a job updates when the user is not an admin", %{conn: conn} do
      user = setup_user()

      client = Factory.insert(:client)
      partner = Factory.insert(:partner)

      employee =
        Factory.insert(:employee, %{
          user: user
        })

      job =
        Factory.insert(:job, %{
          client: client
        })

      contract =
        Factory.insert(:contract, %{
          client: client
        })

      country = Factory.insert(:country)

      employment =
        Factory.insert(:employment, %{
          partner: partner,
          employee: employee,
          job: job,
          contract: contract,
          country: country,
          effective_date: "2021-03-24"
        })

      %{"errors" => errors} =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @update_employment_mutation,
          variables: %{
            id: employment.id,
            effective_date: "2021-04-01"
          }
        })
        |> json_response(200)

      assert List.first(errors) |> Map.get("message") ==
               "User #{user.id} is not authorized to edit employment #{employment.id}"
    end

    test "it deletes an existing employment", %{conn: conn} do
      user = setup_admin_user()

      client = Factory.insert(:client)
      partner = Factory.insert(:partner)

      employee =
        Factory.insert(:employee, %{
          user: user
        })

      job =
        Factory.insert(:job, %{
          client: client
        })

      contract =
        Factory.insert(:contract, %{
          client: client
        })

      country = Factory.insert(:country)

      employment =
        Factory.insert(:employment, %{
          partner: partner,
          employee: employee,
          job: job,
          contract: contract,
          country: country,
          effective_date: "2021-03-24"
        })

      assert Repo.get(Employment, employment.id)

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @delete_employment_mutation,
          variables: %{
            id: employment.id
          }
        })
        |> json_response(200)

      assert %{"data" => %{"deleteEmployment" => %{"id" => employment_id}}} = response
      assert String.to_integer(employment_id) == employment.id
      assert Repo.get(Employment, employment.id) == nil
    end
  end
end
