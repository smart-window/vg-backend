defmodule VelocityWeb.Resolvers.Pto.UserPoliciesTest do
  use VelocityWeb.ConnCase, async: true

  alias Velocity.Contexts.Pto.UserPolicies
  alias Velocity.EmploymentHelpers

  @user_policies_query """
    query UserPolicies($userId: ID, $email: String) {
      userPolicies(userId: $userId, email: $email) {
        id
        user {
          id
          oktaUserUid
          email
        }
        accrualPolicy {
          id
          pegaPolicyId
          label
        }
      }
    }
  """

  describe "query :userPolicies" do
    test "it returns all of the policies assigned to the user", %{conn: conn} do
      user = Factory.insert(:user)
      [accrual_policy | _] = Factory.insert_list(3, :accrual_policy)
      Factory.insert(:level, %{accrual_policy: accrual_policy})

      EmploymentHelpers.setup_employment(user)
      UserPolicies.assign_user_policy(user, Date.utc_today(), accrual_policy)

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @user_policies_query,
          variables: %{
            userId: user.id
          }
        })
        |> json_response(200)

      assert %{"data" => %{"userPolicies" => user_polices}} = response
      assert length(user_polices) == 1
    end

    test "it returns all of the policies assigned to the user with an email", %{conn: conn} do
      user = Factory.insert(:user)
      [accrual_policy | _] = Factory.insert_list(3, :accrual_policy)
      Factory.insert(:level, %{accrual_policy: accrual_policy})

      EmploymentHelpers.setup_employment(user)
      UserPolicies.assign_user_policy(user, Date.utc_today(), accrual_policy)

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @user_policies_query,
          variables: %{
            email: user.email
          }
        })
        |> json_response(200)

      assert %{"data" => %{"userPolicies" => user_polices}} = response
      assert length(user_polices) == 1
    end
  end
end
