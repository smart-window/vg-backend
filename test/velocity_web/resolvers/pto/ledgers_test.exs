defmodule VelocityWeb.Resolvers.Pto.LedgersTest do
  use VelocityWeb.ConnCase, async: true

  alias Velocity.Contexts.Pto.UserPolicies
  alias Velocity.EmploymentHelpers

  @ledgers_query """
    query Ledgers($userId: ID!, $accrualPolicyId: ID!) {
      ledgers(userId: $userId, accrualPolicyId: $accrualPolicyId) {
        id
        eventDate
        eventType
        regularBalance
        regularTransaction
        carryoverBalance
        carryoverTransaction
      }
    }
  """

  describe "query :userPolicies" do
    test "it returns ledgers for the user and policy", %{conn: conn} do
      user = Factory.insert(:user)
      [accrual_policy | _] = Factory.insert_list(3, :accrual_policy)
      level = Factory.insert(:level, %{accrual_policy: accrual_policy})

      EmploymentHelpers.setup_employment(user)
      UserPolicies.assign_user_policy(user, Date.utc_today(), accrual_policy)
      Factory.insert_list(5, :ledger, %{user: user, accrual_policy: accrual_policy, level: level})

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @ledgers_query,
          variables: %{
            userId: user.id,
            accrualPolicyId: accrual_policy.id
          }
        })
        |> json_response(200)

      assert %{"data" => %{"ledgers" => ledgers}} = response
      # assignment ledger (1) + 5 ledgers
      assert length(ledgers) == 6
    end
  end
end
