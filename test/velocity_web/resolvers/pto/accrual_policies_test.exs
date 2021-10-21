defmodule VelocityWeb.Resolvers.Pto.AccrualPoliciesTest do
  use VelocityWeb.ConnCase, async: true

  @accrual_policies_query """
    query {
      accrualPolicies {
        id
        pegaPolicyId
        label
        firstAccrualPolicy
        carryoverDay
      }
    }
  """

  describe "query :accrual_policies" do
    test "it returns all of the accrual policies", %{conn: conn} do
      number_of_policies = 3

      Factory.insert_list(number_of_policies, :accrual_policy)

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", "bonkers")
        |> post("/graphql", %{
          query: @accrual_policies_query
        })
        |> json_response(200)

      assert %{"data" => %{"accrualPolicies" => accrual_policies}} = response
      assert length(accrual_policies) == number_of_policies
    end
  end

  @accrual_policy_query """
    query AccrualPolicy($accrualPolicyId: ID!) {
      accrualPolicy(accrualPolicyId: $accrualPolicyId) {
        id
        levels {
          id
        }
      }
    }
  """

  describe "query :accrual_policy" do
    test "it returns an accrual policy with levels", %{conn: conn} do
      accrual_policy = Factory.insert(:accrual_policy)
      Factory.insert_list(3, :level, %{accrual_policy: accrual_policy})

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", "bonkers")
        |> post("/graphql", %{
          query: @accrual_policy_query,
          variables: %{
            accrualPolicyId: accrual_policy.id
          }
        })
        |> json_response(200)

      assert %{"data" => %{"accrualPolicy" => %{"levels" => levels}}} = response
      assert length(levels) == 3
    end
  end
end
