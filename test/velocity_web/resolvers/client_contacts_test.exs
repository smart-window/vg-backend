defmodule VelocityWeb.Resolvers.ClientContactsTest do
  use VelocityWeb.ConnCase, async: true

  @upsert_mpoc """
    mutation UpsertMpoc(
      $clientId: ID,
      $countryId: ID,
      $userId: ID,
    ) {
      upsert_mpoc(
        clientId: $clientId,
        countryId: $countryId,
        userId: $userId,
      ) {
        id
        user {
          id
        }
        country {
          id
        }
        client {
          id
        }
        is_primary
      }
    }
  """

  @set_region_mpoc """
    mutation SetRegionMpoc(
      $clientId: ID,
      $regionId: ID,
      $userId: ID,
    ) {
      set_region_mpoc(
        clientId: $clientId,
        regionId: $regionId,
        userId: $userId,
      ) {
        id
        user {
          id
        }
        country {
          id
        }
        client {
          id
        }
        is_primary
      }
    }
  """

  @set_organization_mpoc """
    mutation SetOrganizationMpoc(
      $clientId: ID,
      $userId: ID,
    ) {
      set_organization_mpoc(
        clientId: $clientId,
        userId: $userId,
      ) {
        id
        user {
          id
        }
        country {
          id
        }
        client {
          id
        }
        is_primary
      }
    }
  """

  @delete_secondary_contact """
    mutation DeleteSecondaryContact(
      $id: ID,
    ) {
      delete_secondary_contact(
        id: $id,
      ) {
        id
        user {
          id
        }
        country {
          id
        }
        client {
          id
        }
        is_primary
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

  describe "mutation :client_contacts" do
    test "it upsert client mpoc", %{conn: conn} do
      user = setup_user()

      client = Factory.insert(:client)
      country = Factory.insert(:country)
      dbuser = Factory.insert(:user)

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @upsert_mpoc,
          variables: %{
            clientId: client.id,
            countryId: country.id,
            userId: dbuser.id
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "upsert_mpoc" => %{
                   "country" => %{
                     "id" => country_id
                   },
                   "user" => %{
                     "id" => user_id
                   },
                   "client" => %{
                     "id" => client_id
                   },
                   "is_primary" => true
                 }
               }
             } = response

      assert String.to_integer(client_id) == client.id
      assert String.to_integer(country_id) == country.id
      assert String.to_integer(user_id) == dbuser.id
    end

    test "it set client mpoc of a region", %{conn: conn} do
      user = setup_user()

      client = Factory.insert(:client)
      region = Factory.insert(:region)
      country = Factory.insert(:country, %{region_id: region.id})
      dbuser = Factory.insert(:user)

      client_operating_country =
        Factory.insert(:client_operating_country, %{
          client: client,
          country: country
        })

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @set_region_mpoc,
          variables: %{
            clientId: client.id,
            regionId: region.id,
            userId: dbuser.id
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "set_region_mpoc" => [
                   %{
                     "country" => %{
                       "id" => country_id
                     },
                     "user" => %{
                       "id" => user_id
                     },
                     "client" => %{
                       "id" => client_id
                     },
                     "is_primary" => true
                   }
                 ]
               }
             } = response

      assert String.to_integer(client_id) == client.id
      assert String.to_integer(country_id) == country.id
      assert String.to_integer(user_id) == dbuser.id
    end

    test "it set client mpoc of a organize", %{conn: conn} do
      user = setup_user()

      client = Factory.insert(:client)
      region = Factory.insert(:region)
      country = Factory.insert(:country, %{region_id: region.id})
      dbuser = Factory.insert(:user)

      client_operating_country =
        Factory.insert(:client_operating_country, %{
          client: client,
          country: country
        })

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @set_organization_mpoc,
          variables: %{
            clientId: client.id,
            userId: dbuser.id
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "set_organization_mpoc" => [
                   %{
                     "country" => %{
                       "id" => country_id
                     },
                     "user" => %{
                       "id" => user_id
                     },
                     "client" => %{
                       "id" => client_id
                     },
                     "is_primary" => true
                   }
                 ]
               }
             } = response

      assert String.to_integer(client_id) == client.id
      assert String.to_integer(country_id) == country.id
      assert String.to_integer(user_id) == dbuser.id
    end

    test "it delete a client secondary contact", %{conn: conn} do
      user = setup_user()

      client = Factory.insert(:client)
      country = Factory.insert(:country)
      dbuser = Factory.insert(:user)

      client_contact =
        Factory.insert(:client_contact, %{
          client_id: client.id,
          country_id: country.id,
          user_id: dbuser.id,
          is_primary: false
        })

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @delete_secondary_contact,
          variables: %{
            id: client_contact.id
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "delete_secondary_contact" => %{
                   "country" => nil,
                   "user" => nil,
                   "client" => nil,
                   "is_primary" => nil
                 }
               }
             } = response
    end
  end
end
