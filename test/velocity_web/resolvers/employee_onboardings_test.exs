defmodule VelocityWeb.Resolvers.EmployeeOnboardingsTest do
  use VelocityWeb.ConnCase, async: true

  alias Velocity.Repo
  alias Velocity.Schema.EmployeeOnboarding

  @get_employee_onboarding_query """
    query($id: ID!) {
      employee_onboarding(id: $id) {
        id
        employment {
          id
        }
        process {
          id
        }
        signature_status
        immigration
        benefits
      }
    }
  """

  @get_all_employee_onboardings_query """
    query($pageSize: Int, $sortColumn: String, $sortDirection: String, $filterBy: [FilterBy], $searchBy: String) {
      employeeOnboardings(pageSize: $pageSize, sortColumn: $sortColumn, sortDirection: $sortDirection, filterBy: $filterBy, searchBy: $searchBy) {
        row_count
        employee_onboardings {
          id
          employment {
            id
          }
          process {
            id
          }
          signature_status
          immigration
          benefits
        }
      }
    }
  """

  @create_employee_onboarding_mutation """
    mutation CreateEmployeeOnboarding($employment_id: ID!, $process_id: ID!, $signature_status: String!, $immigration: Boolean!, $benefits: Boolean!) {
      createEmployeeOnboarding(employment_id: $employment_id, process_id: $process_id, signature_status: $signature_status, immigration: $immigration, benefits: $benefits) {
        id
        employment {
          id
        }
        process {
          id
        }
        signature_status
        immigration
        benefits
      }
    }
  """

  @update_employee_onboarding_mutation """
    mutation UpdateEmployeeOnboarding($id: ID!, $signature_status: String!) {
      updateEmployeeOnboarding(id: $id, signature_status: $signature_status) {
        id
        employment {
          id
        }
        process {
          id
        }
        signature_status
        immigration
        benefits
      }
    }
  """

  @delete_employee_onboarding_mutation """
    mutation DeleteEmployeeOnboarding($id: ID!) {
      deleteEmployeeOnboarding(id: $id) {
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

  def setup_employment(user) do
    # set up an employment for the user
    partner = Factory.insert(:partner)
    client = Factory.insert(:client)
    job = Factory.insert(:job, %{client: client})
    contract = Factory.insert(:contract, %{client: client})
    region = Factory.insert(:region)
    country_of_employment = Factory.insert(:country, %{region: region})
    employee = Factory.insert(:employee, %{user: user})

    Factory.insert(:employment, %{
      effective_date: "2020-01-01",
      partner: partner,
      employee: employee,
      job: job,
      contract: contract,
      country: country_of_employment
    })
  end

  describe "query :employee_onboardings" do
    test "it gets a employee_onboarding", %{conn: conn} do
      user = setup_user()
      employment = setup_employment(user)

      process = Factory.insert(:process)

      employee_onboarding =
        Factory.insert(:employee_onboarding, %{
          employment_id: employment.id,
          process_id: process.id,
          signature_status: "not_signed",
          immigration: false,
          benefits: true
        })

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @get_employee_onboarding_query,
          variables: %{
            id: employee_onboarding.id
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "employee_onboarding" => %{
                   "id" => employee_onboarding_id,
                   "employment" => %{
                     "id" => employment_id
                   },
                   "process" => %{
                     "id" => process_id
                   },
                   "signature_status" => "not_signed",
                   "immigration" => false,
                   "benefits" => true
                 }
               }
             } = response

      assert String.to_integer(employee_onboarding_id) == employee_onboarding.id
      assert String.to_integer(employment_id) == employment.id
      assert String.to_integer(process_id) == process.id
    end

    test "it gets all employee_onboardings", %{conn: conn} do
      user = setup_user()
      employment1 = setup_employment(user)
      employment2 = setup_employment(user)

      process_template = Factory.insert(:process_template)
      process1 = Factory.insert(:process, %{process_template: process_template})
      process2 = Factory.insert(:process, %{process_template: process_template})

      employee_onboarding1 =
        Factory.insert(:employee_onboarding, %{
          employment_id: employment1.id,
          process_id: process1.id,
          signature_status: "not_signed",
          immigration: false,
          benefits: true
        })

      employee_onboarding2 =
        Factory.insert(:employee_onboarding, %{
          employment_id: employment2.id,
          process_id: process2.id,
          signature_status: "signed",
          immigration: true,
          benefits: false
        })

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @get_all_employee_onboardings_query,
          variables: %{
            pageSize: 5,
            sortColumn: "full_name",
            sortDirection: "asc"
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "employeeOnboardings" => %{
                   "row_count" => row_count,
                   "employee_onboardings" => [
                     %{
                       "benefits" => true,
                       "employment" => %{"id" => employment_id1},
                       "id" => employee_onboarding_id1,
                       "immigration" => false,
                       "process" => %{"id" => process_id1},
                       "signature_status" => "not_signed"
                     },
                     %{
                       "benefits" => false,
                       "employment" => %{"id" => employment_id2},
                       "id" => employee_onboarding_id2,
                       "immigration" => true,
                       "process" => %{"id" => process_id2},
                       "signature_status" => "signed"
                     }
                   ]
                 }
               }
             } = response

      assert row_count == 2
      assert String.to_integer(employee_onboarding_id1) == employee_onboarding1.id
      assert String.to_integer(employment_id1) == employment1.id
      assert String.to_integer(process_id1) == process1.id
      assert String.to_integer(employee_onboarding_id2) == employee_onboarding2.id
      assert String.to_integer(employment_id2) == employment2.id
      assert String.to_integer(process_id2) == process2.id
    end
  end

  describe "mutation :employee_onboardings" do
    test "it creates an employee_onboarding", %{conn: conn} do
      user = setup_user()
      employment = setup_employment(user)

      process = Factory.insert(:process)

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @create_employee_onboarding_mutation,
          variables: %{
            employment_id: employment.id,
            process_id: process.id,
            signature_status: "signed",
            immigration: true,
            benefits: false
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "createEmployeeOnboarding" => %{
                   "id" => employee_onboarding_id,
                   "employment" => %{
                     "id" => employment_id
                   },
                   "process" => %{
                     "id" => process_id
                   },
                   "signature_status" => "signed",
                   "immigration" => true,
                   "benefits" => false
                 }
               }
             } = response

      assert String.to_integer(employment_id) == employment.id
      assert String.to_integer(process_id) == process.id
      assert Repo.get(EmployeeOnboarding, employee_onboarding_id)
    end

    test "it updates an existing employee_onboarding", %{conn: conn} do
      user = setup_user()
      employment = setup_employment(user)

      process = Factory.insert(:process)

      employee_onboarding =
        Factory.insert(:employee_onboarding, %{
          employment_id: employment.id,
          process_id: process.id,
          signature_status: "not_signed",
          immigration: false,
          benefits: true
        })

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @update_employee_onboarding_mutation,
          variables: %{
            id: employee_onboarding.id,
            signature_status: "signed"
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "updateEmployeeOnboarding" => %{
                   "id" => employee_onboarding_id,
                   "employment" => %{
                     "id" => employment_id
                   },
                   "process" => %{
                     "id" => process_id
                   },
                   "signature_status" => "signed",
                   "immigration" => false,
                   "benefits" => true
                 }
               }
             } = response

      assert String.to_integer(employee_onboarding_id) == employee_onboarding.id
      assert String.to_integer(employment_id) == employment.id
      assert String.to_integer(process_id) == process.id
    end

    test "it deletes an existing employee_onboarding", %{conn: conn} do
      user = setup_user()
      employment = setup_employment(user)

      process = Factory.insert(:process)

      employee_onboarding =
        Factory.insert(:employee_onboarding, %{
          employment_id: employment.id,
          process_id: process.id,
          signature_status: "not_signed",
          immigration: false,
          benefits: true
        })

      assert Repo.get(EmployeeOnboarding, employee_onboarding.id)

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @delete_employee_onboarding_mutation,
          variables: %{
            id: employee_onboarding.id
          }
        })
        |> json_response(200)

      assert %{"data" => %{"deleteEmployeeOnboarding" => %{"id" => employee_onboarding_id}}} =
               response

      assert String.to_integer(employee_onboarding_id) == employee_onboarding.id
      assert Repo.get(EmployeeOnboarding, employee_onboarding.id) == nil
    end
  end
end
