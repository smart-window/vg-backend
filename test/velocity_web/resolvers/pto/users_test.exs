defmodule VelocityWeb.Resolvers.Pto.UsersTest do
  use VelocityWeb.ConnCase, async: true

  alias Velocity.Contexts.Pto.UserPolicies
  alias Velocity.EmploymentHelpers

  @users_query """
    query Users {
      users {
        id
        oktaUserUid
        full_name
        email
      }
    }
  """

  describe "query :users" do
    test "it returns all users that are assigned to policies", %{conn: conn} do
      [user | _] = Factory.insert_list(5, :user)
      [accrual_policy | _] = Factory.insert_list(3, :accrual_policy)
      Factory.insert(:level, %{accrual_policy: accrual_policy})

      EmploymentHelpers.setup_employment(user)
      UserPolicies.assign_user_policy(user, Date.utc_today(), accrual_policy)

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @users_query
        })
        |> json_response(200)

      assert %{"data" => %{"users" => users}} = response
      assert length(users) == 1
    end
  end
end
