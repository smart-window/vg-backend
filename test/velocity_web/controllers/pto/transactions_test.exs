defmodule VelocityWeb.Controllers.Pto.TransactionsTest do
  use VelocityWeb.ConnCase, async: true

  alias Velocity.Contexts.Pto.AccrualPolicies
  alias Velocity.Contexts.Pto.Levels
  alias Velocity.Contexts.Pto.UserPolicies
  alias Velocity.Contexts.Users
  alias Velocity.EmploymentHelpers

  @okta_user_uid "abc1234"
  @pega_policy_id "p1234"

  @user %{
    "okta_user_uid" => @okta_user_uid,
    "first_name" => "Bob",
    "last_name" => "Loblaw",
    "start_date" => "20200916",
    "email" => "b@g.co"
  }

  @accrual_policy %{
    "pega_policy_id" => @pega_policy_id,
    "label" => "coollabel",
    "first_accrual_policy" => "prorate",
    "carryover_day" => "anniversary",
    "pool" => "p",
    "levels" => [
      %{
        "start_date_interval" => 0,
        "start_date_interval_unit" => "days",
        "pega_level_id" => "p1234l12",
        "accrual_amount" => 2.0,
        "accrual_period" => "days",
        "accrual_frequency" => 1.0,
        "max_days" => 10,
        "carryover_limit" => 1,
        "carryover_limit_type" => "wow",
        "accrual_calculation_month_day" => "first",
        "accrual_calculation_week_day" => 1,
        "accrual_calculation_year_month" => "w",
        "accrual_calculation_year_day" => 2
      },
      %{
        "start_date_interval" => 10,
        "start_date_interval_unit" => "days",
        "pega_level_id" => "p1234l31",
        "accrual_amount" => 2.0,
        "accrual_period" => "days",
        "accrual_frequency" => 1.0,
        "max_days" => 10,
        "carryover_limit" => 1,
        "carryover_limit_type" => "wow",
        "accrual_calculation_month_day" => "first",
        "accrual_calculation_week_day" => 1,
        "accrual_calculation_year_month" => "w",
        "accrual_calculation_year_day" => 2
      }
    ]
  }

  @nightly_accrual %{
    "user" => @user,
    "accrual_policy" => @accrual_policy
  }

  @taken %{
    "accrual_policy" => @accrual_policy,
    "external_case_id" => "somecase",
    "AdjustmentNotes" => "some note",
    "amount" => -5.0,
    "user" => @user
  }

  @withdrawn %{
    "accrual_policy" => @accrual_policy,
    "ledger_id" => nil,
    "AdjustmentNotes" => "some note",
    "user" => @user
  }

  @manual_addition %{
    "accrual_policy" => @accrual_policy,
    "external_case_id" => "def543",
    "amount" => 3,
    "AdjustmentNotes" => "some note",
    "user" => @user
  }

  @manual_deduction %{
    "accrual_policy" => @accrual_policy,
    "external_case_id" => "abc123",
    "amount" => -5,
    "AdjustmentNotes" => "some note",
    "user" => @user
  }

  describe "POST /transactions/nightly_accrual" do
    setup do
      {:ok, user} = Users.create(@user)

      {:ok, %{accrual_policy: accrual_policy}} =
        @accrual_policy
        |> AtomicMap.convert(safe: false)
        |> AccrualPolicies.create()

      EmploymentHelpers.setup_employment(user)

      {:ok, _user_policy} =
        UserPolicies.assign_user_policy(user, @user["start_date"], accrual_policy)

      {:ok, user: user, accrual_policy: accrual_policy}
    end

    test "it returns an initial_accrual when it is the first accrual", %{
      conn: conn
    } do
      response =
        conn
        |> post(Routes.transactions_path(conn, :nightly_accrual), @nightly_accrual)
        |> json_response(200)

      assert %{"event_type" => "initial_accrual"} = response
    end
  end

  describe "POST /pto/transactions/taken" do
    setup do
      {:ok, user} = Users.create(@user)

      {:ok, %{accrual_policy: accrual_policy}} =
        @accrual_policy
        |> AtomicMap.convert(safe: false)
        |> AccrualPolicies.create()

      EmploymentHelpers.setup_employment(user)

      {:ok, _user_policy} =
        UserPolicies.assign_user_policy(user, @user["start_date"], accrual_policy)

      {:ok, user: user, accrual_policy: accrual_policy}
    end

    test "it returns a 'taken' ledger and reduces the normal balance", %{
      conn: conn,
      accrual_policy: accrual_policy,
      user: user
    } do
      level = Levels.determine_level(@user["start_date"], accrual_policy)

      Factory.insert(:ledger, %{
        accrual_policy: accrual_policy,
        user: user,
        level: level,
        regular_balance: 20
      })

      response =
        conn
        |> post(Routes.transactions_path(conn, :taken), @taken)
        |> json_response(200)

      final_balance = 20 + @taken["amount"]
      assert %{"event_type" => "taken", "regular_balance" => ^final_balance} = response
    end

    test "it adds notes", %{
      conn: conn,
      accrual_policy: accrual_policy,
      user: user
    } do
      level = Levels.determine_level(@user["start_date"], accrual_policy)

      Factory.insert(:ledger, %{
        accrual_policy: accrual_policy,
        user: user,
        level: level,
        regular_balance: 20
      })

      response =
        conn
        |> post(Routes.transactions_path(conn, :taken), @taken)
        |> json_response(200)

      %{"notes" => notes} = response
      assert notes
    end
  end

  describe "POST /pto/transactions/withdrawn" do
    setup do
      {:ok, user} = Users.create(@user)

      {:ok, %{accrual_policy: accrual_policy}} =
        @accrual_policy
        |> AtomicMap.convert(safe: false)
        |> AccrualPolicies.create()

      EmploymentHelpers.setup_employment(user)

      {:ok, _user_policy} =
        UserPolicies.assign_user_policy(user, @user["start_date"], accrual_policy)

      {:ok, user: user, accrual_policy: accrual_policy}
    end

    test "it re-adds pto equal to the amount in the ledger that is being withdrawn", %{
      conn: conn,
      user: user,
      accrual_policy: accrual_policy
    } do
      level = Levels.determine_level(@user["start_date"], accrual_policy)

      pto_taken_ledger =
        Factory.insert(:ledger, %{
          accrual_policy: accrual_policy,
          user: user,
          level: level,
          event_type: "taken",
          regular_balance: 7,
          regular_transaction: -3,
          carryover_balance: 0,
          carryover_transaction: 0
        })

      response =
        conn
        |> post(
          Routes.transactions_path(conn, :withdrawn),
          @withdrawn
          |> Map.put("ledger_id", pto_taken_ledger.id)
        )
        |> json_response(200)

      assert %{
               "regular_balance" => 10.0,
               "regular_transaction" => 3.0,
               "event_type" => "withdrawn"
             } = response
    end

    test "it adds notes", %{
      conn: conn,
      user: user,
      accrual_policy: accrual_policy
    } do
      level = Levels.determine_level(@user["start_date"], accrual_policy)

      pto_taken_ledger =
        Factory.insert(:ledger, %{
          accrual_policy: accrual_policy,
          user: user,
          level: level,
          event_type: "taken",
          regular_balance: 7,
          regular_transaction: -3,
          carryover_balance: 0,
          carryover_transaction: 0
        })

      response =
        conn
        |> post(
          Routes.transactions_path(conn, :withdrawn),
          @withdrawn
          |> Map.put("ledger_id", pto_taken_ledger.id)
        )
        |> json_response(200)

      assert %{
               "notes" => notes
             } = response

      assert notes
    end
  end

  describe "POST /pto/transactions/manual_adjustment" do
    setup do
      {:ok, user} = Users.create(@user)

      {:ok, %{accrual_policy: accrual_policy}} =
        @accrual_policy
        |> AtomicMap.convert(safe: false)
        |> AccrualPolicies.create()

      EmploymentHelpers.setup_employment(user)

      {:ok, _user_policy} =
        UserPolicies.assign_user_policy(user, @user["start_date"], accrual_policy)

      {:ok, user: user, accrual_policy: accrual_policy}
    end

    test "it returns a 'manual_adjustment' ledger with a deducted amount", %{conn: conn} do
      response =
        conn
        |> post(Routes.transactions_path(conn, :manual_adjustment), @manual_deduction)
        |> json_response(200)

      assert %{
               "regular_balance" => -5.0,
               "regular_transaction" => -5.0,
               "event_type" => "manual_adjustment"
             } = response
    end

    test "it returns a 'manual_adjustment' ledger with an added amount", %{conn: conn} do
      response =
        conn
        |> post(Routes.transactions_path(conn, :manual_adjustment), @manual_addition)
        |> json_response(200)

      assert %{
               "regular_balance" => 3.0,
               "regular_transaction" => 3.0,
               "event_type" => "manual_adjustment"
             } = response
    end

    test "it adds notes", %{conn: conn} do
      response =
        conn
        |> post(Routes.transactions_path(conn, :manual_adjustment), @manual_addition)
        |> json_response(200)

      assert %{
               "notes" => notes
             } = response

      assert notes
    end
  end
end
