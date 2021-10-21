defmodule VelocityWeb.Controllers.Pto.UserPoliciesTest do
  use VelocityWeb.ConnCase, async: true

  alias Velocity.Contexts.Pto.Ledgers
  alias Velocity.EmploymentHelpers
  alias Velocity.Repo
  alias Velocity.Schema.Pto.Ledger
  alias Velocity.Schema.Pto.UserPolicy
  alias Velocity.Schema.User
  alias Velocity.Utils.Dates, as: Utils

  import Ecto.Query
  import ExUnit.CaptureLog

  # 20200514
  # 2015-01-23T23:50:07Z
  @assign_user_policies %{
    "user" => %{
      "start_date" => "20210323",
      "okta_user_uid" => "abc1234"
    },
    "pega_policy_ids" => [
      "p1234"
    ]
  }

  describe "POST /pto/user_policies" do
    test "it assigns the user to the policies", %{conn: conn} do
      user =
        Factory.insert(:user, %{okta_user_uid: @assign_user_policies["user"]["okta_user_uid"]})

      EmploymentHelpers.setup_employment(user)

      accrual_policy =
        Factory.insert(:accrual_policy, %{
          pega_policy_id: List.first(@assign_user_policies["pega_policy_ids"])
        })

      Factory.insert_list(3, :level, %{accrual_policy: accrual_policy})

      conn
      |> post(Routes.user_policies_path(conn, :assign_user_policy), @assign_user_policies)
      |> json_response(200)

      assert Repo.one(UserPolicy)
    end

    test "it is idempotent", %{conn: conn} do
      user =
        Factory.insert(:user, %{okta_user_uid: @assign_user_policies["user"]["okta_user_uid"]})

      EmploymentHelpers.setup_employment(user)

      accrual_policy =
        Factory.insert(:accrual_policy, %{
          pega_policy_id: List.first(@assign_user_policies["pega_policy_ids"])
        })

      Factory.insert_list(3, :level, %{accrual_policy: accrual_policy})

      conn
      |> post(Routes.user_policies_path(conn, :assign_user_policy), @assign_user_policies)
      |> json_response(200)

      conn
      |> post(Routes.user_policies_path(conn, :assign_user_policy), @assign_user_policies)
      |> json_response(200)

      assert Repo.one(UserPolicy)
    end

    test "it saves the user start date", %{conn: conn} do
      user =
        Factory.insert(:user, %{okta_user_uid: @assign_user_policies["user"]["okta_user_uid"]})

      EmploymentHelpers.setup_employment(user)

      accrual_policy =
        Factory.insert(:accrual_policy, %{
          pega_policy_id: List.first(@assign_user_policies["pega_policy_ids"])
        })

      Factory.insert_list(3, :level, %{accrual_policy: accrual_policy})

      conn
      |> post(Routes.user_policies_path(conn, :assign_user_policy), @assign_user_policies)
      |> json_response(200)

      user = Repo.one(User)
      assert user.start_date
    end

    test "it calculates pto from the given start_date on assignment", %{conn: conn} do
      user =
        Factory.insert(:user, %{okta_user_uid: @assign_user_policies["user"]["okta_user_uid"]})

      EmploymentHelpers.setup_employment(user)

      accrual_policy =
        Factory.insert(:accrual_policy, %{
          pega_policy_id: List.first(@assign_user_policies["pega_policy_ids"])
        })

      Factory.insert_list(3, :level, %{accrual_policy: accrual_policy})

      conn
      |> post(Routes.user_policies_path(conn, :assign_user_policy), @assign_user_policies)
      |> json_response(200)

      first_ledger = Ledgers.first_ledger_entry(user, accrual_policy)

      day_after_start_date =
        Timex.shift(Utils.parse_pega_date!(@assign_user_policies["user"]["start_date"]), days: 1)

      assert Timex.compare(
               first_ledger.event_date,
               day_after_start_date,
               :day
             ) == 0
    end

    test "if there is no level it returns a 200", %{conn: conn} do
      user =
        Factory.insert(:user, %{okta_user_uid: @assign_user_policies["user"]["okta_user_uid"]})

      EmploymentHelpers.setup_employment(user)

      Factory.insert(:accrual_policy, %{
        pega_policy_id: List.first(@assign_user_policies["pega_policy_ids"])
      })

      assert capture_log(fn ->
               conn
               |> post(
                 Routes.user_policies_path(conn, :assign_user_policy),
                 @assign_user_policies
               )
               |> json_response(200)
             end) =~ "UndefinedFunctionError" || "BadMapError"
    end
  end

  describe "DELETE /pto/user_policies - delete user_policies" do
    test "it removes all ledgers for matching user_policies", %{conn: conn} do
      user = Factory.insert(:user)
      accrual_policy_1 = Factory.insert(:accrual_policy, %{pega_policy_id: "12345"})
      accrual_policy_2 = Factory.insert(:accrual_policy, %{pega_policy_id: "54321"})

      Factory.insert(:user_policy, %{user: user, accrual_policy: accrual_policy_1})
      Factory.insert(:user_policy, %{user: user, accrual_policy: accrual_policy_2})
      Factory.insert(:ledger, %{user: user, accrual_policy: accrual_policy_1})
      Factory.insert(:ledger, %{user: user, accrual_policy: accrual_policy_2})

      params = %{
        user: %{
          okta_user_uid: user.okta_user_uid
        },
        pega_policy_ids: [
          accrual_policy_1.pega_policy_id,
          accrual_policy_2.pega_policy_id
        ]
      }

      conn
      |> delete(Routes.user_policies_path(conn, :remove_user_policies, params))
      |> json_response(200)

      assert Repo.all(UserPolicy) == []
      assert Repo.all(from(l in Ledger, where: l.deleted == false)) == []
    end
  end

  describe "GET /pto/user_policies - list user_policies" do
    test "it returns a list of all of the policies the user is assigned to", %{conn: conn} do
      user = Factory.insert(:user)
      accrual_policy_1 = Factory.insert(:accrual_policy, %{pega_policy_id: "12345"})
      accrual_policy_2 = Factory.insert(:accrual_policy, %{pega_policy_id: "54321"})

      Factory.insert(:user_policy, %{user: user, accrual_policy: accrual_policy_1})
      Factory.insert(:user_policy, %{user: user, accrual_policy: accrual_policy_2})
      Factory.insert(:ledger, %{user: user, accrual_policy: accrual_policy_1})
      Factory.insert(:ledger, %{user: user, accrual_policy: accrual_policy_2})

      okta_user_uid = user.okta_user_uid

      params = %{
        user: %{
          okta_user_uid: user.okta_user_uid
        }
      }

      response =
        conn
        |> get(Routes.user_policies_path(conn, :list, params))
        |> json_response(200)

      assert %{
               "user" => %{"okta_user_uid" => ^okta_user_uid},
               "pega_policy_ids" => pega_policy_ids
             } = response

      assert length(pega_policy_ids) == 2
    end
  end
end
