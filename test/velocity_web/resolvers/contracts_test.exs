defmodule VelocityWeb.Resolvers.ContractsTest do
  use VelocityWeb.ConnCase, async: true

  alias Velocity.Repo
  alias Velocity.Schema.Contract

  @get_contract_query """
    query($id: ID!) {
      contract(id: $id) {
        id
        client {
          id
        }
      }
    }
  """

  @create_contract_mutation """
    mutation CreateContract($client_id: ID!) {
      createContract(client_id: $client_id) {
        id
        client {
          id
        }
      }
    }
  """

  @update_contract_mutation """
    mutation UpdateContract($id: ID!) {
      updateContract(id: $id) {
        id
        client {
          id
        }
      }
    }
  """

  @delete_contract_mutation """
    mutation DeleteContract($id: ID!) {
      deleteContract(id: $id) {
        id
      }
    }
  """

  def setup_user do
    country = Factory.insert(:country)
    address = Factory.insert(:address, %{country: country})

    Factory.insert(:user, %{
      avatar_url: "http://old.url",
      work_address: address
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

  describe "query :contracts" do
    test "it gets a contract", %{conn: conn} do
      user = setup_user()

      employee =
        Factory.insert(:employee, %{
          user: user
        })

      client = Factory.insert(:client)

      contract =
        Factory.insert(:contract, %{
          client: client
        })

      Factory.insert(:employment, %{
        contract: contract,
        employee: employee
      })

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @get_contract_query,
          variables: %{
            id: contract.id
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "contract" => %{
                   "id" => contract_id,
                   "client" => %{
                     "id" => client_id
                   }
                 }
               }
             } = response

      assert String.to_integer(contract_id) == contract.id
      assert String.to_integer(client_id) == client.id
    end
  end

  describe "mutation :contracts" do
    test "it creates a contract", %{conn: conn} do
      user = setup_admin_user()

      client = Factory.insert(:client)

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @create_contract_mutation,
          variables: %{
            client_id: client.id
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "createContract" => %{
                   "id" => contract_id,
                   "client" => %{
                     "id" => client_id
                   }
                 }
               }
             } = response

      assert String.to_integer(client_id) == client.id
      assert Repo.get(Contract, contract_id)
    end

    test "it updates an existing contract", %{conn: conn} do
      user = setup_admin_user()

      client = Factory.insert(:client)

      contract =
        Factory.insert(:contract, %{
          client: client
        })

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @update_contract_mutation,
          variables: %{
            id: contract.id
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "updateContract" => %{
                   "id" => contract_id,
                   "client" => %{
                     "id" => client_id
                   }
                 }
               }
             } = response

      assert String.to_integer(contract_id) == contract.id
      assert String.to_integer(client_id) == client.id
    end

    test "it returns an error on a job updates when the user is not an admin", %{conn: conn} do
      user = setup_user()

      client = Factory.insert(:client)

      contract =
        Factory.insert(:contract, %{
          client: client
        })

      %{"errors" => errors} =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @update_contract_mutation,
          variables: %{
            id: contract.id
          }
        })
        |> json_response(200)

      assert List.first(errors) |> Map.get("message") ==
               "User #{user.id} is not authorized to edit contract #{contract.id}"
    end

    test "it deletes an existing contract", %{conn: conn} do
      user = setup_admin_user()

      client = Factory.insert(:client)

      contract =
        Factory.insert(:contract, %{
          client: client
        })

      assert Repo.get(Contract, contract.id)

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @delete_contract_mutation,
          variables: %{
            id: contract.id
          }
        })
        |> json_response(200)

      assert %{"data" => %{"deleteContract" => %{"id" => contract_id}}} = response
      assert String.to_integer(contract_id) == contract.id
      assert Repo.get(Contract, contract.id) == nil
    end
  end
end
