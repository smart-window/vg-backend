defmodule VelocityWeb.Resolvers.PermissionsTest do
  use VelocityWeb.ConnCase, async: true

  @permissions_query """
    query {
      permissions {
        id
        slug
      }
    }
  """

  describe "query :permissions" do
    test "it returns the permissions for the current user", %{conn: conn} do
      user = Factory.insert(:user)
      group = Factory.insert(:group, %{slug: "super_admin", okta_group_slug: "admins"})
      permission = Factory.insert(:permission, %{slug: "can_act_as_any_company"})
      Factory.insert(:group_permission, group_id: group.id, permission_id: permission.id)
      Factory.insert(:user_group, %{user_id: user.id, group_id: group.id})

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @permissions_query
        })
        |> json_response(200)

      assert %{"data" => %{"permissions" => [returned_permission | _]}} = response
      assert returned_permission["slug"] == permission.slug
    end

    test "it returns the permissions for the current user when the user has a role assignment", %{
      conn: conn
    } do
      user = Factory.insert(:user)

      group = Factory.insert(:group, %{slug: "super_admin", okta_group_slug: "admins"})
      permission_from_group = Factory.insert(:permission, %{slug: "can_act_as_any_company"})

      Factory.insert(:group_permission,
        group_id: group.id,
        permission_id: permission_from_group.id
      )

      Factory.insert(:user_group, %{user_id: user.id, group_id: group.id})

      role = Factory.insert(:role, %{slug: "payroll_manager"})
      permission_from_role = Factory.insert(:permission, %{slug: "can_approve_payroll_requests"})
      Factory.insert(:role_permission, role_id: role.id, permission_id: permission_from_role.id)
      Factory.insert(:user_role, %{user_id: user.id, role_id: role.id})

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @permissions_query
        })
        |> json_response(200)

      assert %{"data" => %{"permissions" => all_permissions}} = response
      assert Enum.count(all_permissions) == 2
    end
  end

  @role_assignments_query """
    query {
      roleAssignments {
        id
        userId
        employeeId
        clientId
        countryId
      }
    }
  """
  describe "query :role_assignments_query" do
    test "it returns the role assignments for the current user", %{conn: conn} do
      user = Factory.insert(:user)
      employee = Factory.insert(:user)
      country = Factory.insert(:country)
      client = Factory.insert(:client)
      group = Factory.insert(:group, %{slug: "super_admin", okta_group_slug: "admins"})
      permission_from_group = Factory.insert(:permission, %{slug: "can_act_as_any_company"})

      Factory.insert(:group_permission,
        group_id: group.id,
        permission_id: permission_from_group.id
      )

      Factory.insert(:user_group, %{user_id: user.id, group_id: group.id})

      role = Factory.insert(:role, %{slug: "payroll_manager"})
      permission_from_role = Factory.insert(:permission, %{slug: "can_approve_payroll_requests"})
      Factory.insert(:role_permission, role_id: role.id, permission_id: permission_from_role.id)
      Factory.insert(:user_role, %{user_id: user.id, role_id: role.id})

      Factory.insert(:role_assignment, %{
        user_id: user.id,
        role_id: role.id,
        employee_id: employee.id
      })

      Factory.insert(:role_assignment, %{
        user_id: user.id,
        role_id: role.id,
        country_id: country.id
      })

      Factory.insert(:role_assignment, %{
        user_id: user.id,
        role_id: role.id,
        client_id: client.id
      })

      # getting an error here: Postgrex expected a binary, got true. Any thoughts?
      # assignment3 = Factory.insert(:role_assignment, %{user_id: user.id, role_id: role.id, assignment_type: "global"})

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @role_assignments_query
        })
        |> json_response(200)

      assert %{"data" => %{"roleAssignments" => all_assignments}} = response
      assert Enum.count(all_assignments) == 3
    end
  end
end
