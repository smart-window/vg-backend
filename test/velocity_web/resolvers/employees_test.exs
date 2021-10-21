defmodule VelocityWeb.Resolvers.EmployeesTest do
  use VelocityWeb.ConnCase, async: true

  alias Velocity.Repo
  alias Velocity.Schema.Employee

  @get_employee_query """
    query($id: ID!) {
      employee(id: $id) {
        id
        user {
          id
        }
      }
    }
  """

  @create_employee_mutation """
    mutation CreateEmployee($user_id: ID!) {
      createEmployee(user_id: $user_id) {
        id
        user {
          id
        }
      }
    }
  """

  @update_employee_mutation """
    mutation UpdateEmployee($id: ID!) {
      updateEmployee(id: $id) {
        id
        user {
          id
        }
      }
    }
  """

  @delete_employee_mutation """
    mutation DeleteEmployee($id: ID!) {
      deleteEmployee(id: $id) {
        id
      }
    }
  """

  @employees_list_query """
    query paginatedEmployeesReport($pageSize: Int, $sortColumn: String, $sortDirection: String, $filterBy: [FilterBy], $searchBy: String) {
      paginatedEmployeesReport(pageSize: $pageSize, sortColumn: $sortColumn, sortDirection: $sortDirection, filterBy: $filterBy, searchBy: $searchBy) {
        rowCount
        employeeReportItems {
          fullName
          id
          partnerName
          clientName
          avatarUrl
          email
          phone
          regionName
          title
          employmentType
          countryName
          country {
            id
            region {
              id
            }
          }
        }
      }
    }
  """

  def setup_user do
    country = Factory.insert(:country)
    address = Factory.insert(:address, %{country_id: country.id})

    Factory.insert(:user, %{
      avatar_url: "http://old.url",
      work_address: address
    })
  end

  describe "query :employees" do
    test "it gets an employee", %{conn: conn} do
      user = setup_user()

      employee =
        Factory.insert(:employee, %{
          user: user
        })

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @get_employee_query,
          variables: %{
            id: employee.id
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "employee" => %{
                   "id" => employee_id,
                   "user" => %{
                     "id" => user_id
                   }
                 }
               }
             } = response

      assert String.to_integer(employee_id) == employee.id
      assert String.to_integer(user_id) == user.id
    end
  end

  describe "mutation :employees" do
    test "it creates a employee", %{conn: conn} do
      user = setup_user()

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @create_employee_mutation,
          variables: %{
            user_id: user.id
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "createEmployee" => %{
                   "id" => employee_id,
                   "user" => %{
                     "id" => user_id
                   }
                 }
               }
             } = response

      assert String.to_integer(user_id) == user.id
      assert Repo.get(Employee, employee_id)
    end

    test "it updates an existing employee", %{conn: conn} do
      user = setup_user()

      employee =
        Factory.insert(:employee, %{
          user: user
        })

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @update_employee_mutation,
          variables: %{
            id: employee.id
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "updateEmployee" => %{
                   "id" => employee_id,
                   "user" => %{
                     "id" => user_id
                   }
                 }
               }
             } = response

      assert String.to_integer(employee_id) == employee.id
      assert String.to_integer(user_id) == user.id
    end

    test "it deletes an existing employee", %{conn: conn} do
      user = setup_user()

      employee =
        Factory.insert(:employee, %{
          user: user
        })

      assert Repo.get(Employee, employee.id)

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @delete_employee_mutation,
          variables: %{
            id: employee.id
          }
        })
        |> json_response(200)

      assert %{"data" => %{"deleteEmployee" => %{"id" => employee_id}}} = response
      assert String.to_integer(employee_id) == employee.id
      assert Repo.get(Employee, employee.id) == nil
    end
  end

  describe "query :employees_list_query" do
    test "it gets a list of employees", %{conn: conn} do
      user = setup_user()

      Enum.map(1..10, fn _ ->
        user = setup_user()
        partner = Factory.insert(:partner)
        client = Factory.insert(:client)
        job = Factory.insert(:job, client: client)
        contract = Factory.insert(:contract, client: client)
        country = Factory.insert(:country)

        employee =
          Factory.insert(:employee, %{
            user: user
          })

        Factory.insert(:employment, %{
          effective_date: DateTime.to_date(DateTime.utc_now()),
          employee: employee,
          partner: partner,
          job: job,
          contract: contract,
          country: country
        })
      end)

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @employees_list_query,
          variables: %{
            pageSize: 5,
            sortColumn: "country_name",
            sortDirection: "asc"
          }
        })
        |> json_response(200)

      %{
        "data" => %{
          "paginatedEmployeesReport" => %{
            "employeeReportItems" => employees,
            "rowCount" => row_count
          }
        }
      } = response

      assert row_count == 10
      assert Enum.count(employees) == 5
    end

    test "it sorts correctly", %{conn: conn} do
      user = setup_user()

      Enum.map(1..5, fn index ->
        country = Factory.insert(:country)
        address = Factory.insert(:address, %{country_id: country.id})

        user =
          Factory.insert(:user, %{
            avatar_url: "http://old.url",
            work_address_id: address.id,
            full_name: "#{index}"
          })

        partner = Factory.insert(:partner)
        client = Factory.insert(:client)
        job = Factory.insert(:job, client: client)
        contract = Factory.insert(:contract, client: client)
        country = Factory.insert(:country)

        employee =
          Factory.insert(:employee, %{
            user: user
          })

        Factory.insert(:employment, %{
          effective_date: DateTime.to_date(DateTime.utc_now()),
          employee: employee,
          partner: partner,
          job: job,
          contract: contract,
          country: country
        })
      end)

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @employees_list_query,
          variables: %{
            pageSize: 5,
            sortColumn: "full_name",
            sortDirection: "asc"
          }
        })
        |> json_response(200)

      %{"data" => %{"paginatedEmployeesReport" => %{"employeeReportItems" => employees}}} =
        response

      employee_names = Enum.map(employees, & &1["fullName"])
      sorted_employee_names = Enum.sort(employee_names)

      assert List.first(employees)["fullName"] == List.first(sorted_employee_names)
      assert List.last(employees)["fullName"] == List.last(sorted_employee_names)
    end
  end
end
