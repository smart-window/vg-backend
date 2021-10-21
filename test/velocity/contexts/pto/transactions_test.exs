defmodule Velocity.Contexts.Pto.TransactionsTest do
  use Velocity.DataCase, async: true

  alias Timex.Interval
  alias Velocity.Contexts.Pto.Levels
  alias Velocity.Contexts.Pto.Transactions
  alias Velocity.Contexts.Pto.UserPolicies
  alias Velocity.EmploymentHelpers
  alias Velocity.Schema.Pto.Ledger

  import Ecto.Query
  import Mox

  describe "Transactions.should_accrue?/3 (days)" do
    test "when the event date falls on a 'multiple' of the accrual frequency it returns the accrual amount" do
      date = Date.utc_today()
      hire_date = Timex.shift(date, days: -15)

      user = Factory.insert(:user)
      accrual_policy = Factory.insert(:accrual_policy)

      level =
        Factory.insert(:level, %{
          accrual_period: "days",
          accrual_amount: 0.5,
          accrual_frequency: 15,
          start_date_interval_unit: "days",
          start_date_interval: 1
        })

      with_date = Levels.with_effective_date(hire_date, level)

      Factory.insert(:ledger, %{
        user: user,
        accrual_policy: accrual_policy,
        level: level,
        regular_balance: 0,
        carryover_balance: 0
      })

      assert Transactions.should_accrue?(
               date,
               with_date,
               hire_date
             )
    end

    test "it handles 'last'" do
      {:ok, start_date} = Date.new(2020, 11, 29)
      {:ok, date} = Date.new(2020, 11, 30)

      assert Transactions.should_accrue?(
               date,
               %{
                 accrual_period: "months",
                 accrual_amount: 1,
                 accrual_calculation_month_day: "last",
                 effective_date: start_date
               },
               nil
             )
    end
  end

  describe "Transactions.should_accrue?/3 (months)" do
    setup do
      user = Factory.insert(:user)
      accrual_policy = Factory.insert(:accrual_policy)

      {:ok, %{user: user, accrual_policy: accrual_policy}}
    end

    test "it parses the string `15` and matches when the month day is 15" do
      date = ~D[2020-10-15]
      hire_date = Timex.shift(date, months: -1)

      user = Factory.insert(:user)
      accrual_policy = Factory.insert(:accrual_policy)

      level =
        Factory.insert(:level, %{
          accrual_period: "months",
          accrual_amount: 1,
          accrual_frequency: 1,
          accrual_calculation_month_day: "15",
          start_date_interval_unit: "days",
          start_date_interval: 0
        })

      with_date = Levels.with_effective_date(hire_date, level)

      Factory.insert(:ledger, %{
        user: user,
        accrual_policy: accrual_policy,
        level: level,
        regular_balance: 0,
        carryover_balance: 0
      })

      assert Transactions.should_accrue?(date, with_date, hire_date)
    end

    test "it parses `15,last` correctly on the 15th" do
      date = ~D[2020-10-15]
      hire_date = Timex.shift(date, months: -1)

      user = Factory.insert(:user)
      accrual_policy = Factory.insert(:accrual_policy)

      level =
        Factory.insert(:level, %{
          accrual_period: "months",
          accrual_amount: 1,
          accrual_frequency: 1,
          accrual_calculation_month_day: "15,last",
          start_date_interval_unit: "days",
          start_date_interval: 0
        })

      with_date = Levels.with_effective_date(hire_date, level)

      Factory.insert(:ledger, %{
        user: user,
        accrual_policy: accrual_policy,
        level: level,
        regular_balance: 0,
        carryover_balance: 0
      })

      assert Transactions.should_accrue?(date, with_date, hire_date)
    end

    test "it parses `15,last` correctly on the last" do
      date = ~D[2020-10-31]
      hire_date = Timex.shift(date, months: -1)

      user = Factory.insert(:user)
      accrual_policy = Factory.insert(:accrual_policy)

      level =
        Factory.insert(:level, %{
          accrual_period: "months",
          accrual_amount: 1,
          accrual_frequency: 1,
          accrual_calculation_month_day: "15,last",
          start_date_interval_unit: "days",
          start_date_interval: 0
        })

      with_date = Levels.with_effective_date(hire_date, level)

      Factory.insert(:ledger, %{
        user: user,
        accrual_policy: accrual_policy,
        level: level,
        regular_balance: 0,
        carryover_balance: 0
      })

      assert Transactions.should_accrue?(date, with_date, hire_date)
    end

    test "it parses `1,15` correctly on the 1st" do
      date = ~D[2020-10-01]
      hire_date = Timex.shift(date, months: -1)

      with_date =
        Levels.with_effective_date(hire_date, %{
          accrual_period: "months",
          accrual_amount: 1,
          accrual_frequency: 1,
          accrual_calculation_month_day: "1,15",
          start_date_interval_unit: "days",
          start_date_interval: 0
        })

      assert Transactions.should_accrue?(date, with_date, hire_date)
    end

    test "it works with 'semi-monthly' number format (3,28)" do
      first_date = ~D[2020-10-03]
      second_date = ~D[2020-10-28]
      hire_date = Timex.shift(first_date, months: -1)

      with_date =
        Levels.with_effective_date(hire_date, %{
          accrual_period: "months",
          accrual_amount: 1,
          accrual_frequency: 1,
          accrual_calculation_month_day: "3,28",
          start_date_interval_unit: "days",
          start_date_interval: 0
        })

      assert Transactions.should_accrue?(first_date, with_date, hire_date)
      assert Transactions.should_accrue?(second_date, with_date, hire_date)
    end
  end

  describe "Transactions.amount_to_accrue/3 (years)" do
    test "it skips the 'first' year" do
    end
  end

  describe "Transactions.prorate_multiplier/3" do
    test "it returns the number of days worked / days_in_current_month" do
      Factory.insert(:accrual_policy, %{
        first_accrual_policy: "prorate"
      })

      level =
        Factory.insert(:level, %{
          accrual_period: "months",
          start_date_interval_unit: "days",
          start_date_interval: 0,
          accrual_amount: 1
        })

      event_date = ~N[2020-10-15 00:00:00]
      hire_date = ~D[2020-10-10]

      assert Transactions.prorate_multiplier(
               event_date,
               Map.put(level, :effective_date, hire_date)
             ) ==
               0.16129032258064516
    end
  end

  describe "Transactions.nightly_accrual/5" do
    setup do
      user = Factory.insert(:user)
      accrual_policy = Factory.insert(:accrual_policy)
      Factory.insert(:level, %{accrual_policy: accrual_policy})

      employment = EmploymentHelpers.setup_employment(user)

      UserPolicies.assign_user_policy(user, user.start_date, accrual_policy)

      {:ok, %{user: user, accrual_policy: accrual_policy, employment: employment}}
    end

    test "it does not duplicate nightly accruals", %{
      user: user,
      accrual_policy: accrual_policy,
      employment: employment
    } do
      Transactions.nightly_accrual(user, employment, accrual_policy)

      query =
        from l in Ledger,
          where:
            l.user_id == ^user.id and l.accrual_policy_id == ^accrual_policy.id and
              l.event_type != "policy_assignment"

      assert Repo.aggregate(query, :count) == 1
    end

    test "it can run multiple times in a succession and not duplicate", %{
      user: user,
      accrual_policy: accrual_policy,
      employment: employment
    } do
      query =
        from l in Ledger,
          where:
            l.user_id == ^user.id and l.accrual_policy_id == ^accrual_policy.id and
              l.event_type != "policy_assignment",
          order_by: l.unique_hash

      [from: ~N[2020-10-15 00:00:00], until: ~N[2020-10-20 00:00:00]]
      |> Interval.new()
      |> Interval.with_step(days: 1)
      |> Enum.map(fn naive_datetime ->
        Transactions.nightly_accrual(user, employment, accrual_policy, naive_datetime)
      end)

      original_count = Repo.aggregate(query, :count)

      [from: ~N[2020-10-15 00:00:00], until: ~N[2020-10-20 00:00:00]]
      |> Interval.new()
      |> Interval.with_step(days: 1)
      |> Enum.map(fn naive_datetime ->
        Transactions.nightly_accrual(user, employment, accrual_policy, naive_datetime)
      end)

      [from: ~N[2020-10-15 00:00:00], until: ~N[2020-10-20 00:00:00]]
      |> Interval.new()
      |> Interval.with_step(days: 1)
      |> Enum.map(fn naive_datetime ->
        Transactions.nightly_accrual(user, employment, accrual_policy, naive_datetime)
      end)

      assert Repo.aggregate(query, :count) == original_count
    end

    test "it fetches the employee_start_date from Pega if nil", %{
      user: user,
      accrual_policy: accrual_policy,
      employment: _employment
    } do
      Velocity.Clients.MockPegaBasic
      |> expect(:hire_date_by_okta_uid, fn _okta_user_uid ->
        {:ok,
         %{
           status: 200,
           body: %{"pxResults" => [%{"EmploymentStatusEffectiveDate" => "2020-01-01"}]}
         }}
      end)

      assert {:ok, _} = Transactions.nightly_accrual(user, nil, accrual_policy)
    end
  end
end
