defmodule VelocityWeb.Resolvers.ClientOnboardingsTest do
  use VelocityWeb.ConnCase, async: true

  alias Velocity.Repo
  alias Velocity.Schema.ClientOnboarding

  @get_client_onboarding_query """
    query($id: ID!) {
      client_onboarding(id: $id) {
        id
        contract {
          id
        }
        process {
          id
        }
      }
    }
  """

  @get_all_client_onboardings_query """
    query($pageSize: Int, $sortColumn: String, $sortDirection: String, $filterBy: [FilterBy], $searchBy: String) {
      clientOnboardings(pageSize: $pageSize, sortColumn: $sortColumn, sortDirection: $sortDirection, filterBy: $filterBy, searchBy: $searchBy) {
        row_count
        client_onboardings {
          id
          contract {
            id
          }
          process {
            id
          }
        }
      }
    }
  """

  @create_client_onboarding_mutation """
    mutation CreateClientOnboarding($contract_id: ID!, $process_id: ID!) {
      createClientOnboarding(contract_id: $contract_id, process_id: $process_id) {
        id
        contract {
          id
        }
        process {
          id
        }
      }
    }
  """

  @update_client_onboarding_mutation """
    mutation UpdateClientOnboarding($id: ID!, $contract_id: ID!) {
      updateClientOnboarding(id: $id, contract_id: $contract_id) {
        id
        contract {
          id
        }
        process {
          id
        }
      }
    }
  """

  @delete_client_onboarding_mutation """
    mutation DeleteClientOnboarding($id: ID!) {
      deleteClientOnboarding(id: $id) {
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

  describe "query :client_onboardings" do
    test "it gets a client_onboarding", %{conn: conn} do
      user = setup_user()

      client = Factory.insert(:client)
      contract = Factory.insert(:contract, %{client: client})
      process = Factory.insert(:process)

      client_onboarding =
        Factory.insert(:client_onboarding, %{
          contract: contract,
          process: process
        })

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @get_client_onboarding_query,
          variables: %{
            id: client_onboarding.id
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "client_onboarding" => %{
                   "id" => client_onboarding_id,
                   "contract" => %{
                     "id" => contract_id
                   },
                   "process" => %{
                     "id" => process_id
                   }
                 }
               }
             } = response

      assert String.to_integer(client_onboarding_id) == client_onboarding.id
      assert String.to_integer(contract_id) == contract.id
      assert String.to_integer(process_id) == process.id
    end

    test "it gets all client_onboardings", %{conn: conn} do
      user = setup_user()

      client = Factory.insert(:client)
      contract = Factory.insert(:contract, %{client: client})
      contract2 = Factory.insert(:contract, %{client: client})
      process_template = Factory.insert(:process_template)
      process = Factory.insert(:process, %{process_template: process_template})
      process2 = Factory.insert(:process, %{process_template: process_template})

      client_onboarding =
        Factory.insert(:client_onboarding, %{
          contract: contract,
          process: process
        })

      client_onboarding2 =
        Factory.insert(:client_onboarding, %{
          contract: contract2,
          process: process2
        })

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @get_all_client_onboardings_query,
          variables: %{
            pageSize: 5,
            sortColumn: "full_name",
            sortDirection: "asc"
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "clientOnboardings" => %{
                   "row_count" => row_count,
                   "client_onboardings" => [
                     %{
                       "id" => client_onboarding_id1,
                       "contract" => %{"id" => contract_id1},
                       "process" => %{"id" => process_id1}
                     },
                     %{
                       "id" => client_onboarding_id2,
                       "contract" => %{"id" => contract_id2},
                       "process" => %{"id" => process_id2}
                     }
                   ]
                 }
               }
             } = response

      assert row_count == 2
      assert String.to_integer(client_onboarding_id1) == client_onboarding.id
      assert String.to_integer(contract_id1) == contract.id
      assert String.to_integer(process_id1) == process.id
      assert String.to_integer(client_onboarding_id2) == client_onboarding2.id
      assert String.to_integer(contract_id2) == contract2.id
      assert String.to_integer(process_id2) == process2.id
    end
  end

  describe "mutation :client_onboardings" do
    test "it creates an client_onboarding", %{conn: conn} do
      user = setup_user()

      client = Factory.insert(:client)
      contract = Factory.insert(:contract, %{client: client})
      process = Factory.insert(:process)

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @create_client_onboarding_mutation,
          variables: %{
            contract_id: contract.id,
            process_id: process.id
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "createClientOnboarding" => %{
                   "id" => client_onboarding_id,
                   "contract" => %{
                     "id" => contract_id
                   },
                   "process" => %{
                     "id" => process_id
                   }
                 }
               }
             } = response

      assert String.to_integer(contract_id) == contract.id
      assert String.to_integer(process_id) == process.id
      assert Repo.get(ClientOnboarding, client_onboarding_id)
    end

    test "it updates an existing client_onboarding", %{conn: conn} do
      user = setup_user()

      client = Factory.insert(:client)
      contract = Factory.insert(:contract, %{client: client})
      contract2 = Factory.insert(:contract, %{client: client})
      process = Factory.insert(:process)

      client_onboarding =
        Factory.insert(:client_onboarding, %{
          contract_id: contract.id,
          process_id: process.id
        })

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @update_client_onboarding_mutation,
          variables: %{
            id: client_onboarding.id,
            contract_id: contract2.id
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "updateClientOnboarding" => %{
                   "id" => client_onboarding_id,
                   "contract" => %{
                     "id" => contract_id
                   },
                   "process" => %{
                     "id" => process_id
                   }
                 }
               }
             } = response

      assert String.to_integer(client_onboarding_id) == client_onboarding.id
      assert String.to_integer(contract_id) == contract2.id
      assert String.to_integer(process_id) == process.id
    end

    test "it deletes an existing client_onboarding", %{conn: conn} do
      user = setup_user()

      client = Factory.insert(:client)
      contract = Factory.insert(:contract, %{client: client})
      process = Factory.insert(:process)

      client_onboarding =
        Factory.insert(:client_onboarding, %{
          contract_id: contract.id,
          process_id: process.id
        })

      assert Repo.get(ClientOnboarding, client_onboarding.id)

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @delete_client_onboarding_mutation,
          variables: %{
            id: client_onboarding.id
          }
        })
        |> json_response(200)

      assert %{"data" => %{"deleteClientOnboarding" => %{"id" => client_onboarding_id}}} =
               response

      assert String.to_integer(client_onboarding_id) == client_onboarding.id
      assert Repo.get(ClientOnboarding, client_onboarding.id) == nil
    end
  end
end
