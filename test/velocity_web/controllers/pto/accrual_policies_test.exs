defmodule VelocityWeb.Controllers.Pto.AccrualPoliciesTest do
  use VelocityWeb.ConnCase, async: true

  alias Velocity.Repo
  alias Velocity.Schema.Pto.AccrualPolicy
  alias Velocity.Schema.Pto.Level

  @create_accrual_policy %{
    "accrual_policy" => %{
      "pega_policy_id" => "p1234",
      "label" => "cool-label",
      "first_accrual_policy" => "prorate",
      "carryover_day" => "first_of_year",
      "pool" => "p",
      "levels" => [
        %{
          "start_date_interval" => 0,
          "start_date_interval_unit" => "days",
          "pega_level_id" => "p1234-l12",
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
          "pega_level_id" => "p1234-l31",
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
  }

  describe "POST /pto/policies" do
    test "it creates an accrual_policy", %{conn: conn} do
      response =
        conn
        |> put_req_header("content-type", "application/json")
        |> post(
          Routes.accrual_policies_path(conn, :create),
          Jason.encode!(@create_accrual_policy)
        )
        |> json_response(200)

      pega_policy_id = Map.get(@create_accrual_policy["accrual_policy"], "pega_policy_id")

      provided_pega_level_ids =
        Map.get(@create_accrual_policy["accrual_policy"], "levels", [])
        |> Enum.map(fn level ->
          level["pega_level_id"]
        end)

      assert %{"accrual_policy" => %{"pega_policy_id" => ^pega_policy_id}} = response

      Enum.each(provided_pega_level_ids, fn level_id ->
        assert %{^level_id => _} = response
      end)

      assert Repo.one(AccrualPolicy)
      assert length(Repo.all(Level)) == length(provided_pega_level_ids)
    end

    test "it is idempotent", %{conn: conn} do
      conn
      |> put_req_header("content-type", "application/json")
      |> post(
        Routes.accrual_policies_path(conn, :create),
        Jason.encode!(@create_accrual_policy)
      )
      |> json_response(200)

      response =
        conn
        |> put_req_header("content-type", "application/json")
        |> post(
          Routes.accrual_policies_path(conn, :create),
          Jason.encode!(@create_accrual_policy)
        )
        |> json_response(200)

      pega_policy_id = Map.get(@create_accrual_policy["accrual_policy"], "pega_policy_id")

      provided_pega_level_ids =
        Map.get(@create_accrual_policy["accrual_policy"], "levels", [])
        |> Enum.map(fn level ->
          level["pega_level_id"]
        end)

      assert %{"accrual_policy" => %{"pega_policy_id" => ^pega_policy_id}} = response

      Enum.each(provided_pega_level_ids, fn level_id ->
        assert %{^level_id => _} = response
      end)

      assert Repo.one(AccrualPolicy)
      assert length(Repo.all(Level)) == length(provided_pega_level_ids)
    end

    test "it updates an existing policy", %{conn: conn} do
      policy_id = @create_accrual_policy["accrual_policy"]["pega_policy_id"]

      accrual_policy =
        Factory.insert(:accrual_policy, %{pega_policy_id: policy_id, label: "some-label"})

      response =
        conn
        |> put_req_header("content-type", "application/json")
        |> post(
          Routes.accrual_policies_path(conn, :create),
          Jason.encode!(@create_accrual_policy)
        )
        |> json_response(200)

      assert %{
               "accrual_policy" => %{
                 "id" => id,
                 "label" => new_label
               }
             } = response

      assert id == accrual_policy.id
      assert new_label == @create_accrual_policy["accrual_policy"]["label"]
    end

    test "it updates an existing level", %{conn: conn} do
      policy_id = @create_accrual_policy["accrual_policy"]["pega_policy_id"]
      level = List.first(@create_accrual_policy["accrual_policy"]["levels"])
      level_id = level["pega_level_id"]
      max_level_days = level["max_days"]

      Factory.insert(:accrual_policy, %{pega_policy_id: policy_id})
      level = Factory.insert(:level, %{pega_level_id: level_id, max_days: max_level_days})

      response =
        conn
        |> put_req_header("content-type", "application/json")
        |> post(
          Routes.accrual_policies_path(conn, :create),
          Jason.encode!(@create_accrual_policy)
        )
        |> json_response(200)

      pega_level_id = level.pega_level_id

      assert %{
               ^pega_level_id => %{
                 "max_days" => max_days
               }
             } = response

      assert max_days == max_level_days
    end
  end

  describe "GET /pto/policies/:id" do
    test "it returns the requested policy", %{conn: conn} do
      policy_id = "pp12345"
      Factory.insert(:accrual_policy, %{pega_policy_id: policy_id})

      response =
        conn
        |> get(Routes.accrual_policies_path(conn, :get, policy_id))
        |> json_response(200)

      assert %{"pega_policy_id" => ^policy_id} = response
    end
  end

  describe "GET /pto/policies" do
    test "it returns all policies", %{conn: conn} do
      Factory.insert_list(4, :accrual_policy)

      response =
        conn
        |> get(Routes.accrual_policies_path(conn, :all))
        |> json_response(200)

      assert %{"policies" => policies} = response
      assert length(policies) == 4
    end
  end

  describe "DELETE /pto/policies/:pega_policy_id" do
    test "it deletes an accrual_policy", %{conn: conn} do
      policy_id = "pp12345"
      Factory.insert(:accrual_policy, %{pega_policy_id: policy_id})

      conn
      |> delete(Routes.accrual_policies_path(conn, :delete, policy_id))
      |> json_response(200)

      assert Repo.all(AccrualPolicy) == []
    end
  end

  describe "DELETE /pto/policies/:pega_policy_id/levels/:pega_level_id" do
    test "it deletes a level", %{conn: conn} do
      policy_id = "pp12345"
      level_id = "pl5431"

      Factory.insert(:accrual_policy, %{pega_policy_id: policy_id})
      Factory.insert(:level, %{pega_level_id: level_id})

      conn
      |> delete(Routes.accrual_policies_path(conn, :delete_level, policy_id, level_id))
      |> json_response(200)

      assert Repo.all(Level) == []
    end

    test "it allows for the delete of a lelvel when there is an associated ledger", %{conn: conn} do
      policy_id = "pp12345"
      level_id = "pl5431"

      accrual_policy = Factory.insert(:accrual_policy, %{pega_policy_id: policy_id})
      level = Factory.insert(:level, %{pega_level_id: level_id})

      Factory.insert(:ledger, %{accrual_policy: accrual_policy, level: level})

      conn
      |> delete(Routes.accrual_policies_path(conn, :delete_level, policy_id, level_id))
      |> json_response(200)

      assert Repo.all(Level) == []
    end
  end
end
