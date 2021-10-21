defmodule Velocity.Contexts.Pto.LevelsTest do
  use Velocity.DataCase, async: true

  alias Velocity.Contexts.Pto.AccrualPolicies
  alias Velocity.Contexts.Pto.Levels
  alias Velocity.Schema.Pto.Level

  describe "Levels.effective_date/2" do
    test "it can handle '7' 'days'" do
      hire_date = Date.utc_today()

      accrual_policy =
        Factory.insert(:level, %{
          start_date_interval_unit: "days",
          start_date_interval: 7
        })

      effective_date = Levels.effective_date(accrual_policy, hire_date)

      assert Timex.diff(effective_date, hire_date, :day) == 7
    end

    test "it can handle '2' 'months'" do
      hire_date = Date.utc_today()

      accrual_policy =
        Factory.insert(:level, %{
          start_date_interval_unit: "months",
          start_date_interval: 2
        })

      effective_date = Levels.effective_date(accrual_policy, hire_date)

      assert Timex.diff(effective_date, hire_date, :month) == 2
    end

    test "it can handle '1' 'years'" do
      hire_date = Date.utc_today()

      accrual_policy =
        Factory.insert(:level, %{
          start_date_interval_unit: "years",
          start_date_interval: 1
        })

      effective_date = Levels.effective_date(accrual_policy, hire_date)

      assert Timex.diff(effective_date, hire_date, :year) == 1
    end
  end

  describe "Levels.determine_level/2" do
    test "it returns the matching level" do
      start_date = Date.utc_today()

      accrual_policy =
        Factory.insert(:accrual_policy, %{
          levels: [
            %{start_date_interval: 0, start_date_interval_unit: "days"},
            %{start_date_interval: 100, start_date_interval_unit: "days"},
            %{start_date_interval: 1000, start_date_interval_unit: "days"}
          ]
        })

      %Level{start_date_interval: 0} = Levels.determine_level(start_date, accrual_policy)
    end
  end

  describe "Levels.sort_levels/2" do
    test "it sorts level" do
      levels =
        Enum.map([1000, 100, 10], fn interval ->
          Factory.insert(:level, %{
            start_date_interval: interval,
            start_date_interval_unit: "days"
          })
        end)

      start_date = Date.utc_today()

      levels = Levels.sort_levels_with_effective_date(start_date, levels)

      levels
      |> Enum.zip([10, 100, 1000])
      |> Enum.each(fn {level, i} ->
        assert level.start_date_interval == i
      end)
    end
  end

  describe "levels" do
    alias Velocity.Schema.Pto.Level

    @valid_attrs %{
      start_date_interval: 1,
      start_date_interval_unit: "days",
      pega_level_id: "L1",
      accrual_amount: 0.5,
      accrual_frequency: 0.5,
      accrual_period: "days",
      max_days: 10.0,
      carryover_limit_type: "my limit type",
      carryover_limit: 5.0,
      accrual_calculation_month_day: "last",
      accrual_calculation_week_day: 1,
      accrual_calculation_year_month: "1",
      accrual_calculation_year_day: 1
    }
    @invalid_attrs %{
      start_date_interval: 1,
      start_date_interval_unit: "fubar",
      pega_level_id: "L1",
      accrual_amount: 0.5,
      accrual_frequency: 0.5,
      accrual_period: "days",
      max_days: 10.0,
      carryover_limit_type: "my limit type",
      carryover_limit: 5.0,
      accrual_calculation_month_day: "last",
      accrual_calculation_week_day: 1,
      accrual_calculation_year_month: "1",
      accrual_calculation_year_day: 1
    }
    @update_attrs %{
      accrual_period: "weeks"
    }

    def accrual_policy_fixture(attrs \\ %{}) do
      pto_type = Factory.insert(:pto_type)

      {:ok, accrual_policy} =
        attrs
        |> Enum.into(%{pto_type_id: pto_type.id})
        |> Enum.into(%{
          pega_policy_id: "P1",
          label: "P1 label",
          first_accrual_policy: "prorate",
          carryover_day: "anniversary",
          pool: "P1 pool"
        })
        |> AccrualPolicies.create_accrual_policy()

      accrual_policy
    end

    def level_fixture(attrs \\ %{}) do
      accrual_policy = accrual_policy_fixture()

      {:ok, level} =
        attrs
        |> Enum.into(%{accrual_policy_id: accrual_policy.id})
        |> Enum.into(@valid_attrs)
        |> Levels.create_level()

      level
    end

    test "create_level with valid data creates a level" do
      accrual_policy = accrual_policy_fixture()

      assert {:ok, %Level{} = level} =
               Levels.create_level(Map.put(@valid_attrs, :accrual_policy_id, accrual_policy.id))

      assert level.pega_level_id == "L1"
    end

    test "create_level with invalid data returns error changeset" do
      accrual_policy = accrual_policy_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Levels.create_level(Map.put(@invalid_attrs, :accrual_policy_id, accrual_policy.id))
    end

    test "update_level with valid data updates the level" do
      level = level_fixture()
      assert {:ok, %Level{} = level} = Levels.update_level(level.id, @update_attrs)
      assert level.accrual_period == "weeks"
    end

    test "update_level with invalid data returns error changeset" do
      level = level_fixture()
      assert {:error, %Ecto.Changeset{}} = Levels.update_level(level.id, @invalid_attrs)
      assert level == Levels.get_level!(level.id)
    end

    test "delete_level deletes the level" do
      level = level_fixture()
      assert {:ok, %Level{}} = Levels.delete_level(level.id)
      assert_raise Ecto.NoResultsError, fn -> Levels.get_level!(level.id) end
    end
  end
end
