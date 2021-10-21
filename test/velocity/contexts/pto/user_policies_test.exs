defmodule Velocity.Contexts.Pto.UserPoliciesTest do
  use Velocity.DataCase, async: true

  alias Velocity.Contexts.Pto.UserPolicies
  alias Velocity.EmploymentHelpers

  describe "user policies" do
    test "it can deactivate a user policy" do
      user = Factory.insert(:user)
      accrual_policy = Factory.insert(:accrual_policy)
      Factory.insert(:level, %{accrual_policy: accrual_policy})
      # employment needed otherwise ledger stuff don't work
      _employment = EmploymentHelpers.setup_employment(user)
      UserPolicies.assign_user_policy(user, user.start_date, accrual_policy)
      end_date = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      UserPolicies.deactivate_user_policy(accrual_policy.id, user.id, end_date)
      user_policy = UserPolicies.get_user_policy!(accrual_policy.id, user.id)
      assert user_policy.end_date == NaiveDateTime.to_date(end_date)
    end
  end
end
