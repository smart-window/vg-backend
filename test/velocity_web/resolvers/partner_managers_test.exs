defmodule VelocityWeb.Resolvers.PartnerManagersTest do
  use VelocityWeb.ConnCase, async: true

  @get_partner_manager_query """
    query($id: ID!) {
      partnerManager(id: $id) {
        id
        job_title
        user {
          id
        }
        partner {
          id
        }
        mpocs {
          id
          is_primary
          user {
            id
          }
        }
      }
    }
  """

  @update_partner_manager_mutation """
    mutation UpdatePartnerManager(
      $id: ID!, 
      $job_title: String!, 
      $email: String!,
      $firstName: String,
      $lastName: String,
      $timezone: String,
      $partnerId: ID,
    ) {
      updatePartnerManager(
        id: $id, 
        job_title: $job_title, 
        email: $email,
        firstName: $firstName,
        lastName: $lastName,
        timezone: $timezone,
        partnerId: $partnerId,
      ) {
        id
        job_title
        user {
          id
          email
          firstName
          lastName
          timezone
        }
        partner {
          id
        }
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

  describe "query :partner_managers" do
    test "it gets a partner_manager", %{conn: conn} do
      user = setup_user()

      partner = Factory.insert(:partner)
      country = Factory.insert(:country)

      partner_manager =
        Factory.insert(:partner_manager, %{
          user_id: user.id,
          partner_id: partner.id,
          job_title: "My Job Title"
        })

      partner_mpoc =
        Factory.insert(:partner_contact, %{
          partner_id: partner.id,
          user_id: user.id,
          country_id: country.id,
          is_primary: true
        })

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @get_partner_manager_query,
          variables: %{
            id: partner_manager.id
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "partnerManager" => %{
                   "id" => partner_manager_id,
                   "job_title" => "My Job Title",
                   "partner" => %{
                     "id" => partner_id
                   },
                   "user" => %{
                     "id" => user_id
                   },
                   "mpocs" => [
                     %{
                       "id" => partner_mpoc_id,
                       "is_primary" => true,
                       "user" => %{
                         "id" => partner_mpoc_user_id
                       }
                     }
                   ]
                 }
               }
             } = response

      assert String.to_integer(partner_manager_id) == partner_manager.id
      assert String.to_integer(partner_id) == partner.id
      assert String.to_integer(user_id) == user.id
      assert String.to_integer(partner_mpoc_id) == partner_mpoc.id
      assert String.to_integer(partner_mpoc_user_id) == user.id
    end
  end

  describe "mutation :partner_managers" do
    test "it updates a existing partner manager", %{conn: conn} do
      user = setup_user()

      partner = Factory.insert(:partner)
      partner2 = Factory.insert(:partner)
      country = Factory.insert(:country)

      partner_manager =
        Factory.insert(:partner_manager, %{
          user_id: user.id,
          partner_id: partner.id
        })

      partner_mpoc =
        Factory.insert(:partner_contact, %{
          partner_id: partner.id,
          user_id: user.id,
          country_id: country.id,
          is_primary: true
        })

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @update_partner_manager_mutation,
          variables: %{
            id: partner_manager.id,
            job_title: "Job 1",
            email: "email",
            firstName: "firstName",
            lastName: "lastName",
            timezone: "EST",
            partnerId: partner2.id
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "updatePartnerManager" => %{
                   "id" => partner_manager_id,
                   "job_title" => "Job 1",
                   "partner" => %{
                     "id" => partner2_id
                   },
                   "user" => %{
                     "id" => user_id,
                     "email" => "email",
                     "firstName" => "firstName",
                     "lastName" => "lastName",
                     "timezone" => "EST"
                   }
                 }
               }
             } = response

      assert String.to_integer(partner_manager_id) == partner_manager.id
      assert String.to_integer(partner2_id) == partner2.id
      assert String.to_integer(user_id) == user.id
    end
  end
end
