defmodule Velocity.Contexts.Pto.AccrualPoliciesTest do
  use Velocity.DataCase, async: true

  alias Velocity.Contexts.Pto.AccrualPolicies

  describe "accrual policies" do
    alias Velocity.Schema.Pto.AccrualPolicy

    @valid_attrs %{
      pega_policy_id: "P1",
      label: "P1 label",
      first_accrual_policy: "prorate",
      carryover_day: "anniversary",
      pool: "P1 pool"
    }
    @invalid_attrs %{
      pega_policy_id: "P1",
      label: "P1 label",
      first_accrual_policy: "prorated",
      carryover_day: "anniversary",
      pool: "P1 pool"
    }
    @update_attrs %{
      label: "P1 label updated"
    }

    def accrual_policy_fixture(pto_type \\ nil, attrs \\ %{}) do
      pto_type =
        if pto_type != nil do
          pto_type
        else
          Factory.insert(:pto_type)
        end

      {:ok, accrual_policy} =
        attrs
        |> Enum.into(%{pto_type_id: pto_type.id})
        |> Enum.into(@valid_attrs)
        |> AccrualPolicies.create_accrual_policy()

      accrual_policy
    end

    def accrual_policy_report_fixture do
      policies = %{}
      pto_type = Factory.insert(:pto_type, %{name: "TOT1"})
      Map.put(policies, :pto_type_1, pto_type)

      for i <- 0..4,
          do:
            accrual_policy_fixture(pto_type, %{
              pega_policy_id: "P" <> Integer.to_string(i),
              label: "P" <> Integer.to_string(i) <> " label"
            })

      pto_type = Factory.insert(:pto_type, %{name: "TOT2"})
      Map.put(policies, :pto_type_2, pto_type)

      for i <- 5..9,
          do:
            accrual_policy_fixture(pto_type, %{
              pega_policy_id: "P" <> Integer.to_string(i),
              label: "P" <> Integer.to_string(i) <> " label"
            })

      pto_type = Factory.insert(:pto_type, %{name: "TOT3"})
      Map.put(policies, :pto_type_3, pto_type)

      for i <- 10..14,
          do:
            accrual_policy_fixture(pto_type, %{
              pega_policy_id: "P" <> Integer.to_string(i),
              label: "P" <> Integer.to_string(i) <> " label"
            })

      pto_type = Factory.insert(:pto_type, %{name: "TOT4"})
      Map.put(policies, :pto_type_4, pto_type)

      for i <- 15..19,
          do:
            accrual_policy_fixture(pto_type, %{
              pega_policy_id: "P" <> Integer.to_string(i),
              label: "P" <> Integer.to_string(i) <> " label"
            })

      policies
    end

    test "create_accrual_policy with valid data creates an accrual policy" do
      pto_type = Factory.insert(:pto_type)

      assert {:ok, %AccrualPolicy{} = accrual_policy} =
               AccrualPolicies.create_accrual_policy(
                 Map.put(@valid_attrs, :pto_type_id, pto_type.id)
               )

      assert accrual_policy.label == "P1 label"
    end

    test "create_accrual_policy with invalid data returns error changeset" do
      pto_type = Factory.insert(:pto_type)

      assert {:error, %Ecto.Changeset{}} =
               AccrualPolicies.create_accrual_policy(
                 Map.put(@invalid_attrs, :pto_type_id, pto_type.id)
               )
    end

    test "update_accrual_policy with valid data updates the team" do
      accrual_policy = accrual_policy_fixture()

      assert {:ok, %AccrualPolicy{} = accrual_policy} =
               AccrualPolicies.update_accrual_policy(accrual_policy.id, @update_attrs)

      assert accrual_policy.label == "P1 label updated"
    end

    test "update_accrual_policy with invalid data returns error changeset" do
      accrual_policy = accrual_policy_fixture()

      assert {:error, %Ecto.Changeset{}} =
               AccrualPolicies.update_accrual_policy(accrual_policy.id, @invalid_attrs)

      assert accrual_policy == AccrualPolicies.get_accrual_policy!(accrual_policy.id)
    end

    test "delete_accrual_policy deletes the accrual policy" do
      accrual_policy = accrual_policy_fixture()
      assert {:ok, %AccrualPolicy{}} = AccrualPolicies.delete_accrual_policy(accrual_policy.id)

      assert_raise Ecto.NoResultsError, fn ->
        AccrualPolicies.get_accrual_policy!(accrual_policy.id)
      end
    end

    test "accrual policy report delivers correctly paged data on name" do
      _report_policies = accrual_policy_report_fixture()
      results = AccrualPolicies.accrual_policies_report(10, :name, :asc, 0, nil, [], nil)
      assert Enum.count(results) == 10
      last_result = Enum.at(results, 9)
      assert last_result.name == "P17 label"

      results =
        AccrualPolicies.accrual_policies_report(
          10,
          :name,
          :asc,
          last_result.id,
          last_result.name,
          [],
          nil
        )

      assert Enum.count(results) == 10
      first_result = Enum.at(results, 0)
      assert first_result.name == "P18 label"
    end

    test "accrual policy report delivers correctly paged data on time off type" do
      _report_policies = accrual_policy_report_fixture()

      results =
        AccrualPolicies.accrual_policies_report(10, :time_off_type, :desc, 0, nil, [], nil)

      assert Enum.count(results) == 10
      last_result = Enum.at(results, 9)
      assert last_result.name == "P14 label"

      results =
        AccrualPolicies.accrual_policies_report(
          10,
          :time_off_type,
          :desc,
          last_result.id,
          last_result.time_off_type,
          [],
          nil
        )

      assert Enum.count(results) == 10
      first_result = Enum.at(results, 0)
      assert first_result.name == "P5 label"
    end

    test "accrual policy report delivers correctly paged data on name with search" do
      _report_policies = accrual_policy_report_fixture()
      results = AccrualPolicies.accrual_policies_report(10, :name, :asc, 0, nil, [], "P2")
      assert Enum.count(results) == 1
      first_result = Enum.at(results, 0)
      assert first_result.name == "P2 label"
    end
  end
end
