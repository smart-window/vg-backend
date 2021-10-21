defmodule VelocityWeb.Resolvers.PtoRequestDaysTest do
  use VelocityWeb.ConnCase, async: true

  alias Velocity.Repo
  alias Velocity.Schema.Pto.PtoRequestDay

  @get_pto_request_day_query """
    query($id: ID!) {
      pto_request_day(id: $id) {
        id
        pto_request_id
        accrual_policy_id
        pto_type_id
        day
        slot
        start_time
        end_time
      }
    }
  """

  @create_pto_request_day_mutation """
    mutation CreatePtoRequestDay($pto_request_id: ID!, $accrual_policy_id: ID!, $pto_type_id: ID!, $day: Date!, $slot: String!) {
      createPtoRequestDay(pto_request_id: $pto_request_id, accrual_policy_id: $accrual_policy_id, pto_type_id: $pto_type_id, day: $day, slot: $slot) {
        id
        pto_request_id
        accrual_policy_id
        pto_type_id
        day
        slot
      }
    }
  """

  @update_pto_request_day_mutation """
    mutation UpdatePtoRequestDay($id: ID!, $slot: String!) {
      updatePtoRequestDay(id: $id, slot: $slot) {
        id
        slot
      }
    }
  """

  @delete_pto_request_day_mutation """
    mutation DeletePtoRequestDay($id: ID!) {
      deletePtoRequestDay(id: $id) {
        id
      }
    }
  """

  def setup_user do
    Factory.insert(:user, %{
      avatar_url: "http://old.url"
    })
  end

  def setup_accrual_policy do
    Factory.insert(:accrual_policy, %{
      pega_policy_id: "P123"
    })
  end

  def setup_pto_type do
    Factory.insert(:pto_type, %{
      name: "Pto Type One"
    })
  end

  def setup_pto_request(user) do
    client = Factory.insert(:client)
    partner = Factory.insert(:partner)

    employee =
      Factory.insert(:employee, %{
        user: user
      })

    job =
      Factory.insert(:job, %{
        client: client
      })

    contract =
      Factory.insert(:contract, %{
        client: client
      })

    country = Factory.insert(:country)

    employment =
      Factory.insert(:employment, %{
        partner: partner,
        employee: employee,
        job: job,
        contract: contract,
        country: country,
        effective_date: "2021-03-24"
      })

    Factory.insert(:pto_request, %{
      employment: employment,
      request_comment: "A PTO Request"
    })
  end

  def setup_pto_request_day(pto_request, accrual_policy, pto_type) do
    Factory.insert(:pto_request_day, %{
      pto_request: pto_request,
      accrual_policy: accrual_policy,
      pto_type: pto_type,
      day: "2021-03-24",
      slot: "all_day"
    })
  end

  describe "query :pto_request_days" do
    test "it gets a pto_request_day", %{conn: conn} do
      user = setup_user()

      pto_request = setup_pto_request(user)
      accrual_policy = setup_accrual_policy()
      pto_type = setup_pto_type()
      pto_request_day = setup_pto_request_day(pto_request, accrual_policy, pto_type)

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @get_pto_request_day_query,
          variables: %{
            id: pto_request_day.id
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "pto_request_day" => %{
                   "id" => pto_request_day_id,
                   "pto_request_id" => pto_request_id,
                   "accrual_policy_id" => accrual_policy_id,
                   "pto_type_id" => pto_type_id,
                   "day" => "2021-03-24",
                   "slot" => "all_day",
                   "start_time" => nil,
                   "end_time" => nil
                 }
               }
             } = response

      assert String.to_integer(pto_request_day_id) == pto_request_day.id
      assert String.to_integer(pto_request_id) == pto_request.id
      assert String.to_integer(accrual_policy_id) == accrual_policy.id
      assert String.to_integer(pto_type_id) == pto_type.id
    end
  end

  describe "mutation :pto_request_days" do
    test "it creates a pto_request_day", %{conn: conn} do
      user = setup_user()

      pto_request = setup_pto_request(user)
      accrual_policy = setup_accrual_policy()
      pto_type = setup_pto_type()

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @create_pto_request_day_mutation,
          variables: %{
            pto_request_id: pto_request.id,
            accrual_policy_id: accrual_policy.id,
            pto_type_id: pto_type.id,
            day: "2021-03-24",
            slot: "afternoon"
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "createPtoRequestDay" => %{
                   "id" => pto_request_day_id,
                   "pto_request_id" => pto_request_id,
                   "accrual_policy_id" => accrual_policy_id,
                   "pto_type_id" => pto_type_id,
                   "day" => "2021-03-24",
                   "slot" => "afternoon"
                 }
               }
             } = response

      assert String.to_integer(pto_request_id) == pto_request.id
      assert String.to_integer(accrual_policy_id) == accrual_policy.id
      assert String.to_integer(pto_type_id) == pto_type.id
      assert Repo.get(PtoRequestDay, pto_request_day_id)
    end

    test "it updates an existing pto_request_day", %{conn: conn} do
      user = setup_user()

      pto_request = setup_pto_request(user)
      accrual_policy = setup_accrual_policy()
      pto_type = setup_pto_type()
      pto_request_day = setup_pto_request_day(pto_request, accrual_policy, pto_type)

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @update_pto_request_day_mutation,
          variables: %{
            id: pto_request_day.id,
            slot: "morning"
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "updatePtoRequestDay" => %{
                   "id" => pto_request_day_id,
                   "slot" => "morning"
                 }
               }
             } = response

      assert String.to_integer(pto_request_day_id) == pto_request_day.id
    end

    test "it deletes an existing pto_request_day", %{conn: conn} do
      user = setup_user()

      pto_request = setup_pto_request(user)
      accrual_policy = setup_accrual_policy()
      pto_type = setup_pto_type()
      pto_request_day = setup_pto_request_day(pto_request, accrual_policy, pto_type)

      assert Repo.get(PtoRequestDay, pto_request_day.id)

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @delete_pto_request_day_mutation,
          variables: %{
            id: pto_request_day.id
          }
        })
        |> json_response(200)

      assert %{"data" => %{"deletePtoRequestDay" => %{"id" => pto_request_day_id}}} = response
      assert String.to_integer(pto_request_day_id) == pto_request_day.id
      assert Repo.get(PtoRequestDay, pto_request_day.id) == nil
    end
  end
end
