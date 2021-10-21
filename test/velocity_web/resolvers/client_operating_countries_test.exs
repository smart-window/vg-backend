defmodule VelocityWeb.Resolvers.ClientOperatingCountriesTest do
  use VelocityWeb.ConnCase, async: true

  @upsert_operating_country """
    mutation UpsertClientOperatingCountry(
      $id: ID,
      $client_id: ID,
      $country_id: ID,
      $probationary_period_length: String,
      $notice_period_length: String,
      $private_medical_insurance: String,
      $other_insurance_offered: String,
      $annual_leave: String,
      $sick_leave: String,
      $standard_additions_deadline: String,
      $client_on_faster_reimbursement: Boolean,
      $standard_allowances_offered: String,
      $standard_bonuses_offered: String,
      $notes: String
    ) {
      upsert_operating_country(
        id: $id,
        client_id: $client_id,
        country_id: $country_id,
        probationary_period_length: $probationary_period_length,
        notice_period_length: $notice_period_length,
        private_medical_insurance: $private_medical_insurance,
        other_insurance_offered: $other_insurance_offered,
        annual_leave: $annual_leave,
        sick_leave: $sick_leave,
        standard_additions_deadline: $standard_additions_deadline,
        client_on_faster_reimbursement: $client_on_faster_reimbursement,
        standard_allowances_offered: $standard_allowances_offered,
        standard_bonuses_offered: $standard_bonuses_offered,
        notes: $notes
      ) {
        id
      }
    }
  """

  @delete_operating_country """
    mutation DeleteClientOperatingCountry($id: ID!) {
      delete_operating_country(id: $id) {
        id
      }
    }
  """

  describe "mutate :client_operating_countries" do
    test "it upserts an operating country", %{conn: conn} do
      user = Factory.insert(:user)
      country = Factory.insert(:country)
      operating_country = Factory.insert(:client_operating_country)

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @upsert_operating_country,
          variables: %{
            client_id: operating_country.client_id,
            country_id: country.id,
            probationary_period_length: "60 days",
            notice_period_length: "60 days",
            private_medical_insurance: "Eighth Day",
            other_insurance_offered: "Vengo",
            annual_leave: "None",
            sick_leave: "Unlimited",
            standard_additions_deadline: "14th",
            client_on_faster_reimbursement: true,
            standard_allowances_offered: "Standard Per USA",
            standard_bonuses_offered: "None",
            notes: "Additional Notes 1"
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{"upsert_operating_country" => %{"id" => oc_id}}
             } = response

      assert String.to_integer(oc_id) != operating_country.id

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @upsert_operating_country,
          variables: %{
            id: oc_id,
            client_on_faster_reimbursement: true
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{"upsert_operating_country" => %{"id" => oc_id1}}
             } = response

      assert oc_id == oc_id1
    end

    test "it deletes an operating country", %{conn: conn} do
      user = Factory.insert(:user)
      operating_country = Factory.insert(:client_operating_country)

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @delete_operating_country,
          variables: %{
            id: operating_country.id
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{"delete_operating_country" => %{"id" => oc_id}}
             } = response

      assert String.to_integer(oc_id) == operating_country.id
    end
  end
end
