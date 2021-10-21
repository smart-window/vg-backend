defmodule VelocityWeb.Resolvers.EmploymentClientManagersTest do
  use VelocityWeb.ConnCase, async: true

  alias Velocity.Repo
  alias Velocity.Schema.EmploymentClientManager

  @get_employment_client_manager_query """
    query($id: ID!) {
      employmentClientManager(id: $id) {
        id
        effective_date
        employment {
          id
        }
        client_manager {
          id
        }
      }
    }
  """

  @create_employment_client_manager_mutation """
    mutation CreateEmploymentClientManager($employment_id: ID!, $client_manager_id: ID!, $effective_date: Date!) {
      createEmploymentClientManager(employment_id: $employment_id, client_manager_id: $client_manager_id, effective_date: $effective_date) {
        id
        effective_date
        employment {
          id
        }
        client_manager {
          id
        }
      }
    }
  """

  @update_employment_client_manager_mutation """
    mutation UpdateEmploymentClientManager($id: ID!, $effective_date: Date!) {
      updateEmploymentClientManager(id: $id, effective_date: $effective_date) {
        id
        effective_date
        employment {
          id
        }
        client_manager {
          id
        }
      }
    }
  """

  @delete_employment_client_manager_mutation """
    mutation DeleteEmploymentClientManager($id: ID!) {
      deleteEmploymentClientManager(id: $id) {
        id
      }
    }
  """

  def setup_user do
    country = Factory.insert(:country)
    address = Factory.insert(:address, %{country: country})

    Factory.insert(:user, %{
      avatar_url: "http://old.url",
      work_address_id: address.id
    })
  end

  describe "query :employment_client_managers" do
    test "it gets an employment to client manager association", %{conn: conn} do
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

      client_manager_user = Factory.insert(:user)

      client_manager =
        Factory.insert(:client_manager, %{
          user: client_manager_user,
          client: client,
          job_title: "My Job Title",
          email: "myemail@fubar.com"
        })

      employment_client_manager =
        Factory.insert(:employment_client_manager, %{
          employment: employment,
          client_manager: client_manager,
          effective_date: "2021-03-25"
        })

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @get_employment_client_manager_query,
          variables: %{
            id: employment_client_manager.id
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "employmentClientManager" => %{
                   "id" => employment_client_manager_id,
                   "employment" => %{
                     "id" => employment_id
                   },
                   "client_manager" => %{
                     "id" => client_manager_id
                   },
                   "effective_date" => "2021-03-25"
                 }
               }
             } = response

      assert String.to_integer(employment_client_manager_id) == employment_client_manager.id
      assert String.to_integer(employment_id) == employment.id
      assert String.to_integer(client_manager_id) == client_manager.id
    end
  end

  describe "mutation :employments" do
    test "it creates an employment", %{conn: conn} do
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

      client_manager_user = Factory.insert(:user)

      client_manager =
        Factory.insert(:client_manager, %{
          user: client_manager_user,
          client: client,
          job_title: "My Job Title",
          email: "myemail@fubar.com"
        })

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @create_employment_client_manager_mutation,
          variables: %{
            employment_id: employment.id,
            client_manager_id: client_manager.id,
            effective_date: "2021-03-25"
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "createEmploymentClientManager" => %{
                   "id" => employment_client_manager_id,
                   "employment" => %{
                     "id" => employment_id
                   },
                   "client_manager" => %{
                     "id" => client_manager_id
                   },
                   "effective_date" => "2021-03-25"
                 }
               }
             } = response

      assert String.to_integer(employment_id) == employment.id
      assert String.to_integer(client_manager_id) == client_manager.id
      assert Repo.get(EmploymentClientManager, employment_client_manager_id)
    end

    test "it updates an existing employment to client manager association", %{conn: conn} do
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

      client_manager_user = Factory.insert(:user)

      client_manager =
        Factory.insert(:client_manager, %{
          user: client_manager_user,
          client: client,
          job_title: "My Job Title",
          email: "myemail@fubar.com"
        })

      employment_client_manager =
        Factory.insert(:employment_client_manager, %{
          employment: employment,
          client_manager: client_manager,
          effective_date: "2021-03-25"
        })

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @update_employment_client_manager_mutation,
          variables: %{
            id: employment_client_manager.id,
            effective_date: "2021-04-01"
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "updateEmploymentClientManager" => %{
                   "id" => _employment_client_manager_id,
                   "employment" => %{
                     "id" => employment_id
                   },
                   "client_manager" => %{
                     "id" => client_manager_id
                   },
                   "effective_date" => "2021-04-01"
                 }
               }
             } = response

      assert String.to_integer(employment_id) == employment.id
      assert String.to_integer(client_manager_id) == client_manager.id
    end

    test "it deletes an existing employment to client manager association", %{conn: conn} do
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

      client_manager_user = Factory.insert(:user)

      client_manager =
        Factory.insert(:client_manager, %{
          user: client_manager_user,
          client: client,
          job_title: "My Job Title",
          email: "myemail@fubar.com"
        })

      employment_client_manager =
        Factory.insert(:employment_client_manager, %{
          employment: employment,
          client_manager: client_manager,
          effective_date: "2021-03-25"
        })

      assert Repo.get(EmploymentClientManager, employment_client_manager.id)

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @delete_employment_client_manager_mutation,
          variables: %{
            id: employment_client_manager.id
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "deleteEmploymentClientManager" => %{"id" => employment_client_manager_id}
               }
             } = response

      assert String.to_integer(employment_client_manager_id) == employment_client_manager.id
      assert Repo.get(EmploymentClientManager, employment_client_manager.id) == nil
    end
  end
end
