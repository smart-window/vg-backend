defmodule VelocityWeb.Controllers.Pto.LedgersTest do
  use VelocityWeb.ConnCase, async: true

  alias Velocity.Contexts.Pto.UserPolicies
  alias Velocity.EmploymentHelpers

  describe "GET /pto/ledgers" do
    setup do
      user = Factory.insert(:user)
      accrual_policy = Factory.insert(:accrual_policy)

      Factory.insert(:ledger, %{
        user: user,
        accrual_policy: accrual_policy,
        event_type: "policy_assignment"
      })

      Factory.insert_list(5, :ledger, %{
        user: user,
        accrual_policy: accrual_policy,
        event_type: "accrual",
        regular_balance: 10,
        carryover_balance: 5
      })

      {:ok, %{user: user, accrual_policy: accrual_policy}}
    end

    test "returns all ledgers for the requested user / policy", %{
      conn: conn,
      user: user,
      accrual_policy: accrual_policy
    } do
      response =
        conn
        |> get(
          Routes.ledgers_path(conn, :list) <>
            "?okta_user_uid=#{user.okta_user_uid}&pega_policy_id=#{accrual_policy.pega_policy_id}"
        )
        |> json_response(200)

      assert %{
               "carryover_balance" => 5.0,
               "regular_balance" => 10.0,
               "transactions" => transactions
             } = response

      assert length(transactions) == 6
    end
  end

  describe "GET /pto/ledgers/summary" do
    setup do
      user = Factory.insert(:user)
      accrual_policy = Factory.insert(:accrual_policy)
      Factory.insert(:level, %{accrual_policy: accrual_policy})

      EmploymentHelpers.setup_employment(user)

      UserPolicies.assign_user_policy(user, user.start_date, accrual_policy)

      Factory.insert(:ledger, %{
        user: user,
        accrual_policy: accrual_policy,
        event_type: "policy_assignment"
      })

      Factory.insert(:ledger, %{
        user: user,
        accrual_policy: accrual_policy,
        event_type: "taken",
        regular_transaction: -5
      })

      Factory.insert(:ledger, %{
        user: user,
        accrual_policy: accrual_policy,
        event_type: "taken",
        carryover_transaction: -1
      })

      Factory.insert(:ledger, %{
        user: user,
        accrual_policy: accrual_policy,
        event_type: "accrual",
        regular_balance: 50,
        carryover_balance: 5
      })

      {:ok, %{user: user, accrual_policy: accrual_policy}}
    end

    test "it returns the balances and days taken for each assigned policy", %{
      conn: conn,
      user: user
    } do
      response =
        conn
        |> get(
          Routes.ledgers_path(conn, :by_user) <>
            "?okta_user_uid=#{user.okta_user_uid}"
        )
        |> json_response(200)

      assert %{
               "accrual_policies" => [
                 %{
                   "carryover_balance" => 5.0,
                   "regular_balance" => 50.0,
                   "pto_taken" => 6.0
                 }
                 | _
               ]
             } = response
    end
  end
end
