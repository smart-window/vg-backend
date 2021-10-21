defmodule VelocityWeb.Resolvers.PartnersTest do
  use VelocityWeb.ConnCase, async: true

  alias Velocity.Repo
  alias Velocity.Schema.Partner

  @get_partner_query """
    query($id: ID!) {
      partner(id: $id) {
        id
        name
        netsuiteId
        type
        statementOfWorkWith
        deploymentAgreementWith
        contactGuidelines
        mpocs {
          id
          is_primary
          user {
            id
          }
          country {
            id
          }
        }
      }
    }
  """

  @create_partner_mutation """
    mutation CreatePartner($name: String!, $netsuite_id: String!, $statement_of_work_with: String!, $deployment_agreement_with: String!, $contact_guidelines: String!) {
      createPartner(name: $name, netsuite_id: $netsuite_id, statement_of_work_with: $statement_of_work_with, deployment_agreement_with: $deployment_agreement_with, contact_guidelines: $contact_guidelines) {
        id
        name
        netsuiteId
        statementOfWorkWith
        deploymentAgreementWith
        contactGuidelines
      }
    }
  """

  @update_partner_mutation """
    mutation UpdatePartner($id: ID!, $name: String!, $netsuite_id: String!, $statement_of_work_with: String!, $deployment_agreement_with: String!, $contact_guidelines: String!) {
      updatePartner(id: $id, name: $name, netsuite_id: $netsuite_id, statement_of_work_with: $statement_of_work_with, deployment_agreement_with: $deployment_agreement_with, contact_guidelines: $contact_guidelines) {
        id
        name
        netsuiteId
        statementOfWorkWith
        deploymentAgreementWith
        contactGuidelines
      }
    }
  """

  @delete_partner_mutation """
    mutation DeletePartner($id: ID!) {
      deletePartner(id: $id) {
        id
      }
    }
  """

  @get_paginated_partners_report """
    query PaginatedPartnersReport(
      $pageSize: Int
      $searchBy: String
      $sortColumn: String
      $filterBy: [FilterBy]
      $sortDirection: String
    ) {
      paginatedPartnersReport (
        pageSize: $pageSize
        searchBy: $searchBy
        sortColumn: $sortColumn
        filterBy: $filterBy
        sortDirection: $sortDirection
      ) {
        rowCount
        partnerReportItems {
          id
          partnerName
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

  describe "query :paginated_partners_report" do
    test "it gets paginated partners", %{conn: conn} do
      user = setup_user()

      partner1 = Factory.insert(:partner)
      partner2 = Factory.insert(:partner)

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @get_paginated_partners_report,
          variables: %{
            pageSize: 5,
            searchBy: "",
            sortColumn: "partner_name",
            filterBy: [],
            sortDirection: "asc"
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "paginatedPartnersReport" => %{
                   "rowCount" => 2,
                   "partnerReportItems" => [
                     %{
                       "id" => partner_id1,
                       "partnerName" => partner_name1
                     },
                     %{
                       "id" => partner_id2,
                       "partnerName" => partner_name2
                     }
                   ]
                 }
               }
             } = response

      assert String.to_integer(partner_id1) == partner1.id
      assert partner_name1 == partner1.name
      assert String.to_integer(partner_id2) == partner2.id
      assert partner_name2 == partner2.name
    end
  end

  describe "query :partners" do
    test "it gets a partner", %{conn: conn} do
      user = setup_user()

      partner = Factory.insert(:partner)
      dbuser = Factory.insert(:user)
      country = Factory.insert(:country)

      partner =
        Factory.insert(:partner, %{
          name: "my_name",
          netsuite_id: "my_netsuite_id",
          type: "in_country_partner",
          statement_of_work_with: "my_statement_of_work_with",
          deployment_agreement_with: "my_deployment_agreement_with",
          contact_guidelines: "my_contact_guidelines"
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
          query: @get_partner_query,
          variables: %{
            id: partner.id
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "partner" => %{
                   "name" => "my_name",
                   "deploymentAgreementWith" => "my_deployment_agreement_with",
                   "contactGuidelines" => "my_contact_guidelines",
                   "netsuiteId" => "my_netsuite_id",
                   "type" => "in_country_partner",
                   "statementOfWorkWith" => "my_statement_of_work_with",
                   "mpocs" => [
                     %{
                       "id" => partner_mpoc_id,
                       "country" => %{
                         "id" => partner_mpoc_country_id
                       },
                       "user" => %{
                         "id" => partner_mpoc_user_id
                       },
                       "is_primary" => true
                     }
                   ]
                 }
               }
             } = response

      assert String.to_integer(partner_mpoc_id) == partner_mpoc.id
      assert String.to_integer(partner_mpoc_country_id) == partner_mpoc.country_id
      assert String.to_integer(partner_mpoc_user_id) == partner_mpoc.user_id
    end
  end

  describe "mutation :partners" do
    test "it creates a partner", %{conn: conn} do
      user = setup_user()

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @create_partner_mutation,
          variables: %{
            name: "my_name",
            netsuite_id: "my_netsuite_id",
            statement_of_work_with: "my_statement_of_work_with",
            deployment_agreement_with: "my_deployment_agreement_with",
            contact_guidelines: "my_contact_guidelines"
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "createPartner" => %{
                   "name" => "my_name",
                   "deploymentAgreementWith" => "my_deployment_agreement_with",
                   "contactGuidelines" => "my_contact_guidelines",
                   "netsuiteId" => "my_netsuite_id",
                   "statementOfWorkWith" => "my_statement_of_work_with"
                 }
               }
             } = response
    end

    test "it updates an existing partner", %{conn: conn} do
      user = setup_user()

      partner =
        Factory.insert(:partner, %{
          name: "my_name",
          netsuite_id: "my_netsuite_id",
          statement_of_work_with: "my_statement_of_work_with",
          deployment_agreement_with: "my_deployment_agreement_with",
          contact_guidelines: "my_contact_guidelines"
        })

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @update_partner_mutation,
          variables: %{
            id: partner.id,
            name: "my_updated_name",
            netsuite_id: "my_updated_netsuite_id",
            statement_of_work_with: "my_updated_statement_of_work_with",
            deployment_agreement_with: "my_updated_deployment_agreement_with",
            contact_guidelines: "my_updated_contact_guidelines"
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "updatePartner" => %{
                   "name" => "my_updated_name",
                   "deploymentAgreementWith" => "my_updated_deployment_agreement_with",
                   "contactGuidelines" => "my_updated_contact_guidelines",
                   "netsuiteId" => "my_updated_netsuite_id",
                   "statementOfWorkWith" => "my_updated_statement_of_work_with"
                 }
               }
             } = response
    end

    test "it deletes an existing partner", %{conn: conn} do
      user = setup_user()

      partner =
        Factory.insert(:partner, %{
          name: "my_name",
          netsuite_id: "my_netsuite_id",
          statement_of_work_with: "my_statement_of_work_with",
          deployment_agreement_with: "my_deployment_agreement_with",
          contact_guidelines: "my_contact_guidelines"
        })

      assert Repo.get(Partner, partner.id)

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @delete_partner_mutation,
          variables: %{
            id: partner.id
          }
        })
        |> json_response(200)

      assert %{"data" => %{"deletePartner" => %{"id" => partner_id}}} = response
      assert String.to_integer(partner_id) == partner.id
      assert Repo.get(Partner, partner.id) == nil
    end
  end
end
