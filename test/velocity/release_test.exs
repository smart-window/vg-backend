defmodule Velocity.ReleaseTest do
  use Velocity.DataCase, async: true
  alias Velocity.EmploymentHelpers
  alias Velocity.Release

  describe "Release.nightly_accrual/2" do
    test "it takes in arguments" do
      policy = Factory.insert(:accrual_policy)
      Factory.insert(:level, %{accrual_policy: policy})
      users = Factory.insert_list(7, :user)

      Enum.each(users, fn user ->
        Factory.insert(:user_policy, %{user: user, accrual_policy: policy})
        EmploymentHelpers.setup_employment(user)
      end)

      assert Release.nightly_accrual("2020-01-30T01:00:00.000Z", "2020-02-02T01:00:00.000Z")
    end
  end
end
