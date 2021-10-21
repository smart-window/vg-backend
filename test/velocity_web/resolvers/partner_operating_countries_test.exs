defmodule VelocityWeb.Resolvers.PartnerOperatingCountriesTest do
  use VelocityWeb.ConnCase, async: true

  @create_partner_operating_country """
    mutation CreatePartnerOperatingCountry(
      $partner_id: ID,
      $country_id: ID,
    ) {
      create_partner_operating_country(
        partner_id: $partner_id,
        country_id: $country_id,
      ) {
        id
        partnerId
        countryId
        primaryService
        secondaryService
        bankCharges
      }
    }
  """

  @delete_partner_operating_country """
    mutation DeletePartnerOperatingCountry(
      $id: ID,
    ) {
      delete_partner_operating_country(
        id: $id,
      ) {
        id
        partnerId
        countryId
        primaryService
        secondaryService
        bankCharges
        partnerOperatingCountryServices {
          id
        }
      }
    }
  """

  @update_partner_operating_country """
    mutation UpdatePartnerOperatingCountry(
      $id: ID
      $countryId: ID
      $primaryService: String
      $secondaryService: String
      $bankCharges: String
      $serviceId: ID
      $fee: Float
      $feeType: String
      $hasSetupFee: Boolean
      $observation: String
      $setupFee: Float
    ) {
      update_partner_operating_country(
        id: $id
        countryId: $countryId
        primaryService: $primaryService
        secondaryService: $secondaryService
        bankCharges: $bankCharges
        serviceId: $serviceId
        fee: $fee
        feeType: $feeType
        hasSetupFee: $hasSetupFee
        observation: $observation
        setupFee: $setupFee
      ) {
        id
        partnerId
        countryId
        primaryService
        secondaryService
        bankCharges
        partnerOperatingCountryServices {
          id
          type
          feeType
          setupFee
          hasSetupFee
          observation
          fee
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

  describe "mutate :partner_operating_countries" do
    test "it create a partner operating country", %{conn: conn} do
      user = setup_user()

      partner = Factory.insert(:partner)
      country = Factory.insert(:country)

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @create_partner_operating_country,
          variables: %{
            partner_id: partner.id,
            country_id: country.id
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "create_partner_operating_country" => %{
                   "partnerId" => partner_id,
                   "countryId" => country_id,
                   "primaryService" => primary_service,
                   "secondaryService" => secondary_service,
                   "bankCharges" => bank_charges
                 }
               }
             } = response

      assert String.to_integer(partner_id) == partner.id
      assert String.to_integer(country_id) == country.id
      assert primary_service == nil
      assert secondary_service == nil
      assert bank_charges == nil
    end

    test "it update a partner operating country", %{conn: conn} do
      user = setup_user()

      partner = Factory.insert(:partner)
      country = Factory.insert(:country)
      primary_service = "primaryService"
      secondary_service = "secondaryService"
      bank_charges = "bankCharges"
      fee = 10
      fee_type = "feeType"
      setup_fee = 20
      has_setup_fee = true
      observation = "observation"

      partner_operating_country =
        Factory.insert(:partner_operating_country, %{
          partner_id: partner.id,
          country_id: country.id
        })

      partner_operating_country_service =
        Factory.insert(:partner_operating_country_service, %{
          partner_operating_country_id: partner_operating_country.id,
          type: "peo_expatriate",
          fee: fee,
          fee_type: fee_type,
          setup_fee: setup_fee,
          has_setup_fee: has_setup_fee,
          observation: observation
        })

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @update_partner_operating_country,
          variables: %{
            id: partner_operating_country.id,
            countryId: country.id,
            primaryService: primary_service,
            secondaryService: secondary_service,
            bankCharges: bank_charges,
            serviceId: partner_operating_country_service.id,
            fee: fee,
            feeType: fee_type,
            setupFee: setup_fee,
            hasSetupFee: has_setup_fee,
            observation: observation
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "update_partner_operating_country" => %{
                   "partnerId" => partner_id,
                   "countryId" => country_id,
                   "primaryService" => partner_operating_country_primary_service,
                   "secondaryService" => partner_operating_country_secondary_service,
                   "bankCharges" => partner_operating_country_bank_charges,
                   "partnerOperatingCountryServices" => [
                     %{
                       "id" => partner_operating_country_service_id,
                       "fee" => partner_operating_country_service_fee,
                       "feeType" => partner_operating_country_service_fee_type,
                       "hasSetupFee" => partner_operating_country_service_has_setup_fee,
                       "type" => partner_operating_country_service_type,
                       "setupFee" => partner_operating_country_service_setup_fee,
                       "observation" => partner_operating_country_service_setup_observation
                     }
                   ]
                 }
               }
             } = response

      assert String.to_integer(partner_id) == partner.id
      assert String.to_integer(country_id) == country.id
      assert partner_operating_country_primary_service == primary_service
      assert partner_operating_country_secondary_service == secondary_service
      assert partner_operating_country_bank_charges == bank_charges

      assert String.to_integer(partner_operating_country_service_id) ==
               partner_operating_country_service.id

      assert partner_operating_country_service_fee == partner_operating_country_service.fee

      assert partner_operating_country_service_fee_type ==
               partner_operating_country_service.fee_type

      assert partner_operating_country_service_has_setup_fee ==
               partner_operating_country_service.has_setup_fee

      assert partner_operating_country_service_type == partner_operating_country_service.type

      assert partner_operating_country_service_setup_fee ==
               partner_operating_country_service.setup_fee

      assert partner_operating_country_service_setup_observation ==
               partner_operating_country_service.observation
    end

    test "it delete a partner operating country", %{conn: conn} do
      user = setup_user()

      partner = Factory.insert(:partner)
      country = Factory.insert(:country)
      primary_service = "primaryService"
      secondary_service = "secondaryService"
      bank_charges = "bankCharges"
      fee = 10
      fee_type = "feeType"
      setup_fee = 20
      has_setup_fee = true
      observation = "observation"

      partner_operating_country =
        Factory.insert(:partner_operating_country, %{
          partner_id: partner.id,
          country_id: country.id,
          primary_service: primary_service,
          secondary_service: secondary_service,
          bank_charges: bank_charges
        })

      partner_operating_country_service =
        Factory.insert(:partner_operating_country_service, %{
          partner_operating_country_id: partner_operating_country.id,
          type: "peo_expatriate",
          fee: fee,
          fee_type: fee_type,
          setup_fee: setup_fee,
          has_setup_fee: has_setup_fee,
          observation: observation
        })

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @delete_partner_operating_country,
          variables: %{
            id: partner_operating_country.id
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "delete_partner_operating_country" => %{
                   "partnerId" => partner_id,
                   "countryId" => country_id,
                   "primaryService" => partner_operating_country_primary_service,
                   "secondaryService" => partner_operating_country_secondary_service,
                   "bankCharges" => partner_operating_country_bank_charges,
                   "partnerOperatingCountryServices" => []
                 }
               }
             } = response

      assert String.to_integer(partner_id) == partner.id
      assert String.to_integer(country_id) == country.id
      assert partner_operating_country_primary_service == primary_service
      assert partner_operating_country_secondary_service == secondary_service
      assert partner_operating_country_bank_charges == bank_charges
    end
  end
end
