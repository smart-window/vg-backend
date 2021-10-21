defmodule VelocityWeb.Resolvers.PartnerContactsTest do
  use VelocityWeb.ConnCase, async: true

  @upsert_partner_mpoc """
    mutation UpsertPartnerMpoc(
      $partnerId: ID,
      $countryId: ID,
      $userId: ID,
    ) {
      upsert_partner_mpoc(
        partnerId: $partnerId,
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
        partner {
          id
        }
        is_primary
      }
    }
  """

  @set_partner_region_mpoc """
    mutation SetPartnerRegionMpoc(
      $partnerId: ID,
      $regionId: ID,
      $userId: ID,
    ) {
      set_partner_region_mpoc(
        partnerId: $partnerId,
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
        partner {
          id
        }
        is_primary
      }
    }
  """

  @set_partner_organization_mpoc """
    mutation SetPartnerOrganizationMpoc(
      $partnerId: ID,
      $userId: ID,
    ) {
      set_partner_organization_mpoc(
        partnerId: $partnerId,
        userId: $userId,
      ) {
        id
        user {
          id
        }
        country {
          id
        }
        partner {
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

  describe "mutation :partner_contacts" do
    test "it upsert partner mpoc", %{conn: conn} do
      user = setup_user()

      partner = Factory.insert(:partner)
      country = Factory.insert(:country)
      dbuser = Factory.insert(:user)

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @upsert_partner_mpoc,
          variables: %{
            partnerId: partner.id,
            countryId: country.id,
            userId: dbuser.id
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "upsert_partner_mpoc" => %{
                   "country" => %{
                     "id" => country_id
                   },
                   "user" => %{
                     "id" => user_id
                   },
                   "partner" => %{
                     "id" => partner_id
                   },
                   "is_primary" => true
                 }
               }
             } = response

      assert String.to_integer(partner_id) == partner.id
      assert String.to_integer(country_id) == country.id
      assert String.to_integer(user_id) == dbuser.id
    end

    test "it set partner mpoc of a region", %{conn: conn} do
      user = setup_user()

      partner = Factory.insert(:partner)
      region = Factory.insert(:region)
      country = Factory.insert(:country, %{region_id: region.id})
      dbuser = Factory.insert(:user)

      partner_operating_country =
        Factory.insert(:partner_operating_country, %{
          partner_id: partner.id,
          country_id: country.id
        })

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @set_partner_region_mpoc,
          variables: %{
            partnerId: partner.id,
            regionId: region.id,
            userId: dbuser.id
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "set_partner_region_mpoc" => [
                   %{
                     "country" => %{
                       "id" => country_id
                     },
                     "user" => %{
                       "id" => user_id
                     },
                     "partner" => %{
                       "id" => partner_id
                     },
                     "is_primary" => true
                   }
                 ]
               }
             } = response

      assert String.to_integer(partner_id) == partner.id
      assert String.to_integer(country_id) == country.id
      assert String.to_integer(user_id) == dbuser.id
    end

    test "it set partner mpoc of a organize", %{conn: conn} do
      user = setup_user()

      partner = Factory.insert(:partner)
      region = Factory.insert(:region)
      country = Factory.insert(:country, %{region_id: region.id})
      dbuser = Factory.insert(:user)

      partner_operating_country =
        Factory.insert(:partner_operating_country, %{
          partner_id: partner.id,
          country_id: country.id
        })

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @set_partner_organization_mpoc,
          variables: %{
            partnerId: partner.id,
            userId: dbuser.id
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "set_partner_organization_mpoc" => [
                   %{
                     "country" => %{
                       "id" => country_id
                     },
                     "user" => %{
                       "id" => user_id
                     },
                     "partner" => %{
                       "id" => partner_id
                     },
                     "is_primary" => true
                   }
                 ]
               }
             } = response

      assert String.to_integer(partner_id) == partner.id
      assert String.to_integer(country_id) == country.id
      assert String.to_integer(user_id) == dbuser.id
    end
  end
end
