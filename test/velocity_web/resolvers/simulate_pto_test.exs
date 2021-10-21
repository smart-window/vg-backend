defmodule VelocityWeb.Resolvers.SimulatePtoTest do
  use VelocityWeb.ConnCase, async: true

  # credo:disable-for-this-file

  @simulate_pto_mutation """
    mutation SimulatePto($startDate: Date!, $endDate: Date!, $user: InputUser!, $accrualPolicy: InputPtoAccrualPolicy!, $takenEvents: [InputTakenEvent], $manualEvents: [InputManualAdjustmentEvent]) {
      simulatePto(startDate: $startDate, endDate: $endDate, user: $user, accrualPolicy: $accrualPolicy, takenEvents: $takenEvents, manualEvents: $manualEvents) {
        id
        eventDate
        eventType
        regularBalance
        regularTransaction
        carryoverBalance
        carryoverTransaction
        userId
        accrualPolicyId
      }
    }
  """

  describe "mutation :simulate_pto" do
    test "it returns the right amount of ledger events", %{conn: conn} do
      response =
        conn
        |> put_req_header("test-only-okta-user-uid", "dingo")
        |> post("/graphql", %{
          query: @simulate_pto_mutation,
          variables: %{
            startDate: "2020-09-10",
            endDate: "2020-11-15",
            user: %{
              oktaUserUid: "abc123",
              email: "larryfitzgerald@gmail.com",
              startDate: "2019-12-22"
            },
            accrualPolicy: %{
              carryoverDay: "first_of_year",
              firstAccrualPolicy: "prorate",
              pegaPolicyId: "12345",
              label: "the best policy",
              levels: [
                pegaLevelId: "l13543",
                carryoverLimitType: "unlimited",
                carryoverLimit: 2,
                maxDays: 10,
                accrualPeriod: "days",
                accrualFrequency: 1,
                accrualAmount: 0.1,
                startDateIntervalUnit: "days",
                startDateInterval: 5,
                accrualCalculationMonthDay: "15",
                accrualCalculationWeekDay: 3,
                accrualCalculationYearDay: 1,
                accrualCalculationYearMonth: "hire"
              ]
            },
            takenEvents: [
              %{
                amount: -1.5,
                date: "2020-11-12"
              }
            ]
          }
        })
        |> json_response(200)

      assert %{"data" => %{"simulatePto" => events}} = response
      assert length(events) == 67
    end

    test "it adds the accruals", %{conn: conn} do
      response =
        conn
        |> put_req_header("test-only-okta-user-uid", "dingo")
        |> post("/graphql", %{
          query: @simulate_pto_mutation,
          variables: %{
            startDate: "2020-09-10",
            endDate: "2020-09-20",
            user: %{
              oktaUserUid: "abc123",
              email: "larryfitzgerald@gmail.com",
              startDate: "2019-12-22"
            },
            accrualPolicy: %{
              carryoverDay: "first_of_year",
              firstAccrualPolicy: "prorate",
              pegaPolicyId: "12345",
              label: "the best policy",
              levels: [
                pegaLevelId: "l13543",
                carryoverLimitType: "unlimited",
                carryoverLimit: 2,
                maxDays: 10,
                accrualPeriod: "days",
                accrualFrequency: 1,
                accrualAmount: 1,
                startDateIntervalUnit: "days",
                startDateInterval: 5,
                accrualCalculationMonthDay: "15",
                accrualCalculationWeekDay: 3,
                accrualCalculationYearDay: 1,
                accrualCalculationYearMonth: "hire"
              ]
            }
          }
        })
        |> json_response(200)

      assert %{"data" => %{"simulatePto" => events}} = response
      assert length(events) == 10
      assert List.last(events)["regularBalance"] == 9
    end

    test "it works with monthly", %{conn: conn} do
      response =
        conn
        |> put_req_header("test-only-okta-user-uid", "dingo")
        |> post("/graphql", %{
          query: @simulate_pto_mutation,
          variables: %{
            startDate: "2020-10-04",
            endDate: "2020-12-23",
            accrualPolicy: %{
              carryoverDay: "first_of_year",
              firstAccrualPolicy: "pay_in_full",
              pegaPolicyId: "12345",
              label: "the best policy",
              levels: [
                pegaLevelId: "l13543",
                carryoverLimitType: "unlimited",
                carryoverLimit: 2,
                maxDays: 10,
                accrualPeriod: "months",
                accrualFrequency: 1,
                accrualAmount: 1.0,
                startDateIntervalUnit: "days",
                startDateInterval: 5,
                accrualCalculationMonthDay: "15",
                accrualCalculationWeekDay: 3,
                accrualCalculationYearDay: 1,
                accrualCalculationYearMonth: "hire"
              ]
            },
            takenEvents: [%{date: "2020-12-10", amount: -1.5}],
            user: %{
              email: "larryfitzgerald@gmail.com",
              startDate: "2020-10-09",
              oktaUserUid: "abc123"
            }
          }
        })
        |> json_response(200)

      assert %{"data" => %{"simulatePto" => events}} = response
      assert length(events) == 5
    end

    test "it works with yearly", %{conn: conn} do
      response =
        conn
        |> put_req_header("test-only-okta-user-uid", "dingo")
        |> post("/graphql", %{
          query: @simulate_pto_mutation,
          variables: %{
            endDate: "2021-01-21",
            startDate: "2020-10-04",
            accrualPolicy: %{
              carryoverDay: "first_of_year",
              firstAccrualPolicy: "prorate",
              pegaPolicyId: "12345",
              label: "the best policy",
              levels: [
                accrualAmount: 10,
                accrualCalculationMonthDay: "15",
                accrualCalculationWeekDay: 3,
                accrualCalculationYearDay: 1,
                accrualCalculationYearMonth: "2",
                accrualFrequency: 1,
                accrualPeriod: "years",
                carryoverLimit: 10,
                carryoverLimitType: "unlimited",
                maxDays: 10,
                pegaLevelId: "l13543",
                startDateInterval: 5,
                startDateIntervalUnit: "days"
              ]
            },
            user: %{
              email: "larryfitzgerald@gmail.com",
              startDate: "2020-10-09",
              oktaUserUid: "abc123"
            }
          }
        })
        |> json_response(200)

      assert %{"data" => %{"simulatePto" => events}} = response
      assert length(events) == 1
    end

    test "it works with a json payload", %{conn: conn} do
      response =
        conn
        |> put_req_header("test-only-okta-user-uid", "dingo")
        |> post("/graphql", %{
          query: @simulate_pto_mutation,
          variables:
            "{\"startDate\":\"2020-12-03\",\"endDate\":\"2023-12-26\",\"user\":{\"oktaUserUid\":\"abc123\",\"email\":\"larryfitzgerald@gmail.com\",\"startDate\":\"2020-12-03\"},\"accrualPolicy\":{\"pegaPolicyId\":\"ln12a5n644i7d6tw\",\"label\":\"the best policy\",\"carryoverDay\":\"first_of_year\",\"firstAccrualPolicy\":\"pay_in_full\",\"levels\":[{\"pegaLevelId\":\"xdtkf317n9f1qsp9\",\"carryoverLimitType\":\"limited\",\"carryoverLimit\":0,\"maxDays\":120,\"accrualPeriod\":\"years\",\"accrualFrequency\":1,\"accrualAmount\":120,\"startDateIntervalUnit\":\"years\",\"startDateInterval\":1,\"accrualCalculationMonthDay\":\"15,last\",\"accrualCalculationWeekDay\":4,\"accrualCalculationYearDay\":78,\"accrualCalculationYearMonth\":\"hire\"}]},\"manualEvents\":[],\"takenEvents\":[{\"amount\":-3,\"date\":\"2021-03-02\"},{\"amount\":-15,\"date\":\"2022-03-23\"}],\"withdrawnEvents\":[]}"
        })
        |> json_response(200)

      assert response
    end
  end
end
