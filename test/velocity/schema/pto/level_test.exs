defmodule Velocity.Schema.Pto.LevelTest do
  use Velocity.DataCase, async: true

  alias Velocity.Schema.Pto.Level

  describe "Level.build/1 (accrual_period: 'days')" do
    test "it works" do
      changeset =
        Level.build(%{
          start_date_interval: 0,
          start_date_interval_unit: "days",
          pega_level_id: "1",
          accrual_amount: 1,
          accrual_period: "days",
          accrual_frequency: 1,
          accrual_policy_id: 1
        })

      assert changeset.valid?
    end
  end
end
