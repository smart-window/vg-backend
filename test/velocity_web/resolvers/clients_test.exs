defmodule VelocityWeb.Resolvers.ClientsTest do
  use VelocityWeb.ConnCase, async: true

  @all_clients_query """
    query {
      clients {
        id
        name
      }
    }
  """

  @get_client_profile_query """
    query($id: ID!) {
      clientProfile(id: $id) {
        id
        address {
          id
        }
        client_managers {
          user {
            full_name
          }
        }
        operating_countries {
          id
        }
        meetings {
          id
        }
        sent_emails {
          id
        }
      }
    }
  """

  @get_client_teams """
    query GetClientTeams($client_id: ID!) {
      client_teams(client_id: $client_id) {
        id
      }
    }
  """

  @update_client """
    mutation UpdateClient(
      $id: ID!
      $name: String
      $timezone: String
      $operational_tier: String
    ) {
      update_client(
        id: $id
        name: $name
        timezone: $timezone
        operational_tier: $operational_tier
      ) {
        id
        name
        timezone
        operational_tier
      }
    }
  """

  describe "query :clients" do
    test "it returns a list of all clients", %{conn: conn} do
      user = Factory.insert(:user)
      mock_client = Factory.insert(:client, %{name: "Velocity Global", id: 1})

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @all_clients_query
        })
        |> json_response(200)

      assert %{"data" => %{"clients" => [%{"name" => client_name}]}} = response
      assert mock_client.name == client_name
    end

    test "it returns a client profile", %{conn: conn} do
      user = Factory.insert(:user)
      client_manager_user = Factory.insert(:user)

      address = Factory.insert(:address)
      client = Factory.insert(:client, %{address: address})

      _client_manager =
        Factory.insert(:client_manager, %{user: client_manager_user, client: client})

      country1 = Factory.insert(:country)

      client_operating_country1 =
        Factory.insert(:client_operating_country, %{country: country1, client: client})

      country2 = Factory.insert(:country)

      client_operating_country2 =
        Factory.insert(:client_operating_country, %{country: country2, client: client})

      meeting1 = Factory.insert(:meeting)
      meeting2 = Factory.insert(:meeting)

      Factory.insert(:client_meeting, %{client: client, meeting: meeting1})
      Factory.insert(:client_meeting, %{client: client, meeting: meeting2})

      sent_email1 = Factory.insert(:sent_email)
      sent_email2 = Factory.insert(:sent_email)

      Factory.insert(:client_sent_email, %{client: client, sent_email: sent_email1})
      Factory.insert(:client_sent_email, %{client: client, sent_email: sent_email2})

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @get_client_profile_query,
          variables: %{
            id: client.id
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "clientProfile" => %{
                   "id" => client_company_id,
                   "address" => %{"id" => client_address_id},
                   "client_managers" => [%{"user" => %{"full_name" => client_manager_name}}],
                   "operating_countries" => [
                     %{"id" => client_operating_country_id1},
                     %{"id" => client_operating_country_id2}
                   ],
                   "meetings" => [
                     %{"id" => client_meeting_id1},
                     %{"id" => client_meeting_id2}
                   ],
                   "sent_emails" => [
                     %{"id" => client_sent_email_id1},
                     %{"id" => client_sent_email_id2}
                   ]
                 }
               }
             } = response

      assert String.to_integer(client_company_id) == client.id
      assert String.to_integer(client_address_id) == address.id
      assert client_manager_name == client_manager_user.full_name
      assert String.to_integer(client_operating_country_id1) == client_operating_country1.id
      assert String.to_integer(client_operating_country_id2) == client_operating_country2.id
      assert String.to_integer(client_meeting_id1) == meeting1.id
      assert String.to_integer(client_meeting_id2) == meeting2.id
      assert String.to_integer(client_sent_email_id1) == sent_email1.id
      assert String.to_integer(client_sent_email_id2) == sent_email2.id
    end

    test "it returns all teams of a client company", %{conn: conn} do
      user = Factory.insert(:user)
      client = Factory.insert(:client)

      team1 = Factory.insert(:team)
      Factory.insert(:client_team, %{client: client, team: team1})
      team2 = Factory.insert(:team)
      Factory.insert(:client_team, %{client: client, team: team2})

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @get_client_teams,
          variables: %{
            client_id: client.id
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "client_teams" => [%{"id" => team1_id}, %{"id" => team2_id}]
               }
             } = response

      assert String.to_integer(team1_id) == team1.id
      assert String.to_integer(team2_id) == team2.id
    end
  end

  describe "mutation :clients" do
    test "it update a client", %{conn: conn} do
      user = Factory.insert(:user)

      client = Factory.insert(:client)

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @update_client,
          variables: %{
            id: client.id,
            name: "name",
            timezone: "EST",
            operational_tier: "standard"
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "update_client" => %{
                   "id" => client_id,
                   "name" => "name",
                   "timezone" => "EST",
                   "operational_tier" => "standard"
                 }
               }
             } = response

      assert String.to_integer(client_id) == client.id
    end
  end
end
