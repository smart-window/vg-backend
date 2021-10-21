defmodule Velocity.JobsTest do
  use Velocity.DataCase, async: true

  alias Velocity.EmploymentHelpers
  alias Velocity.Jobs
  alias Velocity.Repo
  alias Velocity.Schema.Employment
  alias Velocity.Schema.Pto.Ledger

  describe "Jobs.nightly_accrual/0" do
    test "it adds a ledger entry for all users assigned to policies" do
      policy = Factory.insert(:accrual_policy)
      Factory.insert(:level, %{accrual_policy: policy})
      users = Factory.insert_list(7, :user)

      Enum.each(users, fn user ->
        Factory.insert(:user_policy, %{user: user, accrual_policy: policy})
        EmploymentHelpers.setup_employment(user)
      end)

      Jobs.nightly_accrual()

      assert length(Repo.all(Ledger)) == 7
    end

    test "it can run over multiple days" do
      policy = Factory.insert(:accrual_policy)
      Factory.insert(:level, %{accrual_policy: policy})
      users = Factory.insert_list(7, :user)

      Enum.each(users, fn user ->
        Factory.insert(:user_policy, %{user: user, accrual_policy: policy})
        EmploymentHelpers.setup_employment(user)
      end)

      start_date = NaiveDateTime.utc_now()
      end_date = Timex.shift(start_date, days: 3)

      Jobs.nightly_accrual(start_date: start_date, end_date: end_date)

      assert length(Repo.all(Ledger)) == 21
    end
  end

  describe "Jobs.backfill_pto/0" do
    test "it works" do
      levels = Factory.insert_list(8, :level)
      dates = Timex.Interval.new(from: ~D[2020-06-01], until: [days: 100]) |> Enum.take_random(20)

      Enum.map(dates, &Factory.insert(:employment, %{effective_date: &1}))

      employments = Repo.all(from(e in Employment, preload: [employee: :user]))

      Enum.map(employments, &Factory.insert(:pto_request, %{employment: &1}))

      level = Enum.random(levels)

      Enum.map(
        employments,
        &Factory.insert(:user_policy, %{
          user: &1.employee.user,
          accrual_policy_id: level.accrual_policy.id
        })
      )

      Jobs.backfill_pto()
    end
  end
end
