defmodule VelocityWeb.Resolvers.ClientManagersTest do
  use VelocityWeb.ConnCase, async: true

  alias Velocity.Repo
  alias Velocity.Schema.ClientManager

  @get_client_manager_query """
    query($id: ID!) {
      clientManager(id: $id) {
        id
        job_title
        email
        user {
          id
        }
        client {
          id
        }
      }
    }
  """

  @get_client_managers_report_query """
    query GetClientManagersReport($pageSize: Int, $sortColumn: String, $sortDirection: String, $filterBy: [FilterBy], $searchBy: String) {
      paginatedClientManagersReport(pageSize: $pageSize, sortColumn: $sortColumn, sortDirection: $sortDirection, filterBy: $filterBy, searchBy: $searchBy) {
        id
        name
      }
    }
  """

  @create_client_manager_mutation """
    mutation CreateClientManager (
      $clientId: ID!, 
      $jobTitle: String!, 
      $email: String!, 
      $firstName: String!, 
      $lastName: String!
    ) {
      createClientManager(
        clientId: $clientId
        firstName: $firstName
        email: $email
        jobTitle: $jobTitle
        lastName: $lastName
      ) {
        id
        job_title
        email
        user {
          id
        }
        client {
          id
        }
      }
    }
  """

  @update_client_manager_mutation """
    mutation UpdateClientManager($id: ID!, $job_title: String!, $email: String!) {
      updateClientManager(id: $id, job_title: $job_title, email: $email) {
        id
        job_title
        email
        user {
          id
        }
        client {
          id
        }
      }
    }
  """

  @delete_client_manager_mutation """
    mutation DeleteClientManager($id: ID!) {
      deleteClientManager(id: $id) {
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

  describe "query :client_managers" do
    test "it gets a client_manager", %{conn: conn} do
      user = setup_user()

      client = Factory.insert(:client)

      client_manager =
        Factory.insert(:client_manager, %{
          user_id: user.id,
          client_id: client.id,
          job_title: "My Job Title",
          email: "myemail@fubar.com"
        })

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @get_client_manager_query,
          variables: %{
            id: client_manager.id
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "clientManager" => %{
                   "id" => client_manager_id,
                   "job_title" => "My Job Title",
                   "email" => "myemail@fubar.com",
                   "client" => %{
                     "id" => client_id
                   },
                   "user" => %{
                     "id" => user_id
                   }
                 }
               }
             } = response

      assert String.to_integer(client_manager_id) == client_manager.id
      assert String.to_integer(client_id) == client.id
      assert String.to_integer(user_id) == user.id
    end
  end

  describe "mutation :client_managers" do
    test "it creates a client manager", %{conn: conn} do
      user = setup_user()

      client = Factory.insert(:client)

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @create_client_manager_mutation,
          variables: %{
            clientId: client.id,
            firstName: "Mike",
            lastName: "Newman",
            jobTitle: "Manager Software Engineering",
            email: "manager@fubar.com"
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "createClientManager" => %{
                   "job_title" => "Manager Software Engineering",
                   "email" => "manager@fubar.com",
                   "client" => %{
                     "id" => client_id
                   },
                   "user" => %{
                     "id" => user_id
                   }
                 }
               }
             } = response

      assert String.to_integer(client_id) == client.id
    end

    test "it updates an existing client manager", %{conn: conn} do
      user = setup_user()

      client = Factory.insert(:client)

      client_manager =
        Factory.insert(:client_manager, %{
          user_id: user.id,
          client_id: client.id,
          job_title: "My Job Title",
          email: "myemail@fubar.com"
        })

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @update_client_manager_mutation,
          variables: %{
            id: client_manager.id,
            job_title: "My Updated Job Title",
            email: "myupdatedemail@fubar.com"
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "updateClientManager" => %{
                   "id" => client_manager_id,
                   "job_title" => "My Updated Job Title",
                   "email" => "myupdatedemail@fubar.com",
                   "client" => %{
                     "id" => client_id
                   },
                   "user" => %{
                     "id" => user_id
                   }
                 }
               }
             } = response

      assert String.to_integer(client_manager_id) == client_manager.id
      assert String.to_integer(client_id) == client.id
      assert String.to_integer(user_id) == user.id
    end

    test "it deletes an existing client_manager", %{conn: conn} do
      user = setup_user()

      client = Factory.insert(:client)

      client_manager =
        Factory.insert(:client_manager, %{
          user_id: user.id,
          client_id: client.id,
          job_title: "My Job Title",
          email: "myemail@fubar.com"
        })

      assert Repo.get(ClientManager, client_manager.id)

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @delete_client_manager_mutation,
          variables: %{
            id: client_manager.id
          }
        })
        |> json_response(200)

      assert %{"data" => %{"deleteClientManager" => %{"id" => client_manager_id}}} = response
      assert String.to_integer(client_manager_id) == client_manager.id
      assert Repo.get(ClientManager, client_manager.id) == nil
    end
  end
end
