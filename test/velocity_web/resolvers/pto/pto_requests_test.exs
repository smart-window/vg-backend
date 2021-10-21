defmodule VelocityWeb.Resolvers.PtoRequestsTest do
  use VelocityWeb.ConnCase, async: true

  alias Velocity.EmploymentHelpers
  alias Velocity.Repo
  alias Velocity.Schema.Pto.PtoRequest

  @get_pto_request_query """
    query($id: ID!) {
      pto_request(id: $id) {
        id
        request_comment
      }
    }
  """

  @create_pto_request_mutation """
    mutation CreatePtoRequest($employment_id: ID!, $request_comment: String!) {
      createPtoRequest(employment_id: $employment_id, request_comment: $request_comment) {
        id
        employment_id
        request_comment
      }
    }
  """

  @update_pto_request_mutation """
    mutation UpdatePtoRequest($id: ID!, $request_comment: String!) {
      updatePtoRequest(id: $id, request_comment: $request_comment) {
        id
        employment_id
        request_comment
      }
    }
  """

  @delete_pto_request_mutation """
    mutation DeletePtoRequest($id: ID!) {
      deletePtoRequest(id: $id) {
        id
      }
    }
  """

  @create_pto_request_with_days_mutation """
    mutation CreatePtoRequestWithDays(
      $userId: ID!,
      $accrualPolicyId: ID!,
      $requestComment: String,
      $ptoTypeId: ID!,
      $ptoRequestDays: [InputPtoRequestDay]!
    ) {
      createPtoRequestWithDays(
        userId: $userId,
        accrualPolicyId: $accrualPolicyId,
        requestComment: $requestComment,
        ptoTypeId: $ptoTypeId,
        ptoRequestDays: $ptoRequestDays
      ) {
        id
        totalDays
        startDate
        endDate
      }
    }
  """

  def setup_user do
    Factory.insert(:user, %{
      avatar_url: "http://old.url"
    })
  end

  describe "mutation :create_pto_request_with_days" do
    test "it creates a pto_request with days", %{conn: conn} do
      user = setup_user()

      _employment = EmploymentHelpers.setup_employment(user)

      pto_type =
        Factory.insert(:pto_type, %{
          name: "PtoType One"
        })

      accrual_policy =
        Factory.insert(:accrual_policy, %{
          pto_type: pto_type,
          label: "test policy"
        })

      Factory.insert(:user_policy, %{
        user_id: user.id,
        accrual_policy_id: accrual_policy.id
      })

      pto_request_days = [
        %{day: "2021-01-01", slot: "half_day"},
        %{day: "2021-01-02", slot: "half_day"},
        %{day: "2021-01-03", slot: "all_day"},
        %{day: "2021-01-04", slot: "half_day"}
      ]

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @create_pto_request_with_days_mutation,
          variables: %{
            userId: user.id,
            accrualPolicyId: accrual_policy.id,
            requestComment: "request test",
            ptoTypeId: pto_type.id,
            ptoRequestDays: pto_request_days
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "createPtoRequestWithDays" => %{
                   "totalDays" => 2.5
                 }
               }
             } = response
    end
  end

  describe "query :pto_requests" do
    test "it gets a pto_request", %{conn: conn} do
      user = setup_user()

      employment = EmploymentHelpers.setup_employment(user)

      pto_request =
        Factory.insert(:pto_request, %{
          employment: employment,
          request_comment: "Pto Request One"
        })

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @get_pto_request_query,
          variables: %{
            id: pto_request.id
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "pto_request" => %{
                   "id" => pto_request_id,
                   "request_comment" => "Pto Request One"
                 }
               }
             } = response

      assert String.to_integer(pto_request_id) == pto_request.id
    end
  end

  describe "mutation :pto_requests" do
    test "it creates a pto_request", %{conn: conn} do
      user = setup_user()

      employment = EmploymentHelpers.setup_employment(user)

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @create_pto_request_mutation,
          variables: %{
            employment_id: employment.id,
            request_comment: "Pto Request Two"
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "createPtoRequest" => %{
                   "id" => pto_request_id,
                   "employment_id" => employment_id,
                   "request_comment" => "Pto Request Two"
                 }
               }
             } = response

      assert String.to_integer(employment_id) == employment.id
      assert Repo.get(PtoRequest, pto_request_id)
    end

    test "it updates an existing pto_request", %{conn: conn} do
      user = setup_user()

      employment = EmploymentHelpers.setup_employment(user)

      pto_request =
        Factory.insert(:pto_request, %{
          employment: employment,
          request_comment: "Pto Request Three"
        })

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @update_pto_request_mutation,
          variables: %{
            id: pto_request.id,
            request_comment: "Pto Request Three Updated"
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "updatePtoRequest" => %{
                   "id" => pto_request_id,
                   "employment_id" => employment_id,
                   "request_comment" => "Pto Request Three Updated"
                 }
               }
             } = response

      assert String.to_integer(pto_request_id) == pto_request.id
      assert String.to_integer(employment_id) == employment.id
    end

    test "it deletes an existing pto_request", %{conn: conn} do
      user = setup_user()

      employment = EmploymentHelpers.setup_employment(user)

      pto_request =
        Factory.insert(:pto_request, %{
          employment: employment,
          request_comment: "Pto Request Four"
        })

      assert Repo.get(PtoRequest, pto_request.id)

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @delete_pto_request_mutation,
          variables: %{
            id: pto_request.id
          }
        })
        |> json_response(200)

      assert %{"data" => %{"deletePtoRequest" => %{"id" => pto_request_id}}} = response
      assert String.to_integer(pto_request_id) == pto_request.id
      assert Repo.get(PtoRequest, pto_request.id) == nil
    end
  end
end
