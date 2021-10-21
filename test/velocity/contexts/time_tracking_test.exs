defmodule Velocity.Contexts.TimeTrackingTest do
  use Velocity.DataCase, async: true

  alias Velocity.Contexts.TimeTracking

  describe "TimeTracking.can_add_time_entry/4" do
    test "it returns true if the total number of hours plus the hours given is less than 24" do
      user = Factory.insert(:user)
      date = ~D[2020-09-01]
      hours = 10
      Factory.insert(:time_entry, %{user: user, event_date: date, total_hours: 5})

      assert TimeTracking.can_add_time_entry?(user.id, date, hours)
    end

    test "it returns false if the total number of hours plus the hours given exceeds 24" do
      user = Factory.insert(:user)
      date = ~D[2020-09-01]
      hours = 10
      Factory.insert(:time_entry, %{user: user, event_date: date, total_hours: 20})

      refute TimeTracking.can_add_time_entry?(user.id, date, hours)
    end

    test "it returns true if the total number of hours minus the existing hours given exceeds 24" do
      user = Factory.insert(:user)
      date = ~D[2020-09-01]
      hours = 24
      Factory.insert(:time_entry, %{user: user, event_date: date, total_hours: 2})

      assert TimeTracking.can_add_time_entry?(user.id, date, hours, 2)
    end

    test "it returns false if the total number of hours minus the existing hours given exceeds 24" do
      user = Factory.insert(:user)
      date = ~D[2020-09-01]
      hours = 24
      Factory.insert(:time_entry, %{user: user, event_date: date, total_hours: 2})
      Factory.insert(:time_entry, %{user: user, event_date: date, total_hours: 6})

      refute TimeTracking.can_add_time_entry?(user.id, date, hours, 2)
    end

    test "it returns true if the total number of hours on a time entry is 0 and the new hours don't exceed 24 " do
      user = Factory.insert(:user)
      date = ~D[2020-09-01]
      hours = 24

      assert TimeTracking.can_add_time_entry?(user.id, date, hours)
    end
  end
end
