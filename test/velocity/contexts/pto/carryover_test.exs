defmodule Velocity.Contexts.Pto.CarryoverTest do
  use Velocity.DataCase, async: true

  alias Velocity.Contexts.Pto.Carryover

  describe "Carryover.calculate/4" do
    setup do
      user = Factory.insert(:user)

      accrual_policy =
        Factory.insert(:accrual_policy, %{
          carryover_day: "anniversary"
        })

      level =
        Factory.insert(:level, %{
          carryover_limit: 10
        })

      event_date = NaiveDateTime.utc_now()
      employee_start_date = NaiveDateTime.utc_now()

      %{
        user: user,
        accrual_policy: accrual_policy,
        level: level,
        event_date: event_date,
        employee_start_date: employee_start_date
      }
    end

    test "it clears out regular balance", %{
      user: user,
      accrual_policy: accrual_policy,
      event_date: event_date,
      level: level,
      employee_start_date: employee_start_date
    } do
      last_ledger =
        Factory.insert(:ledger, %{
          user: user,
          accrual_policy: accrual_policy,
          level: level,
          regular_balance: 5,
          carryover_balance: 0
        })

      ledger =
        Carryover.calculate(
          %{carryover_day: accrual_policy.carryover_day, carryover_limit: level.carryover_limit},
          last_ledger,
          event_date,
          employee_start_date
        )

      assert ledger.regular_balance == 0
    end

    test "it clears out the carryover balance", %{
      user: user,
      accrual_policy: accrual_policy,
      event_date: event_date,
      level: level,
      employee_start_date: employee_start_date
    } do
      last_ledger =
        Factory.insert(:ledger, %{
          user: user,
          accrual_policy: accrual_policy,
          level: level,
          regular_balance: 5,
          carryover_balance: 0
        })

      ledger =
        Carryover.calculate(
          %{carryover_day: accrual_policy.carryover_day, carryover_limit: level.carryover_limit},
          last_ledger,
          event_date,
          employee_start_date
        )

      assert ledger.carryover_balance == 5
    end

    test "it does nothing if there is nothing to clear out", %{
      user: user,
      accrual_policy: accrual_policy,
      event_date: event_date,
      level: level,
      employee_start_date: employee_start_date
    } do
      last_ledger =
        Factory.insert(:ledger, %{
          user: user,
          accrual_policy: accrual_policy,
          level: level,
          regular_balance: 0,
          carryover_balance: 0
        })

      ledger =
        Carryover.calculate(
          %{carryover_day: accrual_policy.carryover_day, carryover_limit: level.carryover_limit},
          last_ledger,
          event_date,
          employee_start_date
        )

      refute ledger
    end

    test "it maxes out on the carryover limit (10)", %{
      user: user,
      accrual_policy: accrual_policy,
      event_date: event_date,
      level: level,
      employee_start_date: employee_start_date
    } do
      last_ledger =
        Factory.insert(:ledger, %{
          user: user,
          accrual_policy: accrual_policy,
          level: level,
          regular_balance: 15,
          carryover_balance: 0
        })

      carryover_ledger =
        Carryover.calculate(
          %{carryover_day: accrual_policy.carryover_day, carryover_limit: level.carryover_limit},
          last_ledger,
          event_date,
          employee_start_date
        )

      assert carryover_ledger.carryover_balance == 10
      assert carryover_ledger.carryover_transaction == 10
    end

    test "it rolls over the entire regular balance when the limit is not exceeded", %{
      user: user,
      accrual_policy: accrual_policy,
      event_date: event_date,
      level: level,
      employee_start_date: employee_start_date
    } do
      last_ledger =
        Factory.insert(:ledger, %{
          user: user,
          accrual_policy: accrual_policy,
          level: level,
          regular_balance: 8,
          carryover_balance: 0
        })

      carryover_ledger =
        Carryover.calculate(
          %{carryover_day: accrual_policy.carryover_day, carryover_limit: level.carryover_limit},
          last_ledger,
          event_date,
          employee_start_date
        )

      assert carryover_ledger.carryover_balance == 8
      assert carryover_ledger.carryover_transaction == 8
    end

    test "it return nil when no carryover is performed", %{
      user: user,
      accrual_policy: accrual_policy,
      level: level
    } do
      last_ledger =
        Factory.insert(:ledger, %{
          user: user,
          accrual_policy: accrual_policy,
          regular_balance: 8,
          carryover_balance: 0
        })

      event_date = Date.from_iso8601!("2007-01-02")
      employee_start_date = Date.from_iso8601!("2007-01-01")

      carryover_ledger =
        Carryover.calculate(
          %{carryover_day: accrual_policy.carryover_day, carryover_limit: level.carryover_limit},
          last_ledger,
          event_date,
          employee_start_date
        )

      assert carryover_ledger == nil
    end

    test "it does not calculate if the carryover_limit_type is 'unlimited'" do
      carryover_ledger = Carryover.calculate(%{carryover_limit_type: "unlimited"}, nil, nil, nil)

      assert carryover_ledger == nil
    end

    test "it adds the previous years carryover balance until the carryover limit is reached", %{
      user: user,
      accrual_policy: accrual_policy,
      event_date: event_date,
      level: level,
      employee_start_date: employee_start_date
    } do
      last_ledger =
        Factory.insert(:ledger, %{
          user: user,
          accrual_policy: accrual_policy,
          regular_balance: 8,
          carryover_balance: 4
        })

      carryover_ledger =
        Carryover.calculate(
          %{carryover_day: accrual_policy.carryover_day, carryover_limit: level.carryover_limit},
          last_ledger,
          event_date,
          employee_start_date
        )

      assert carryover_ledger.carryover_balance == 10.0
    end
  end

  describe "Carryover.should_perform_carryover?/3" do
    test "anniversary returns true when the event day matches the employee start day" do
      {:ok, other_date, 0} = DateTime.from_iso8601("2007-01-01T00:00:00Z")
      event_date = NaiveDateTime.utc_now()
      employee_start_date = NaiveDateTime.utc_now()

      assert Carryover.should_perform_carryover?(
               "anniversary",
               event_date,
               employee_start_date,
               %{regular_balance: 1}
             )

      refute Carryover.should_perform_carryover?(
               "anniversary",
               other_date,
               employee_start_date,
               %{regular_balance: 1}
             )
    end

    test "first_of_year returns true if the event day is January 1st" do
      {:ok, other_date, 0} = DateTime.from_iso8601("2007-02-02T00:00:00Z")
      {:ok, event_date, 0} = DateTime.from_iso8601("2020-01-01T00:00:00Z")
      employee_start_date = NaiveDateTime.utc_now()

      assert Carryover.should_perform_carryover?(
               "first_of_year",
               event_date,
               employee_start_date,
               %{regular_balance: 1}
             )

      refute Carryover.should_perform_carryover?(
               "first_of_year",
               other_date,
               employee_start_date,
               %{regular_balance: 1}
             )
    end

    test "string (day) returns true if the event day is the same" do
      {:ok, event_date, 0} = DateTime.from_iso8601("2007-02-15T00:00:00Z")
      employee_start_date = NaiveDateTime.utc_now()

      assert Carryover.should_perform_carryover?("46", event_date, employee_start_date, %{
               regular_balance: 1
             })

      refute Carryover.should_perform_carryover?("15", event_date, employee_start_date, %{
               regular_balance: 1
             })
    end
  end
end
