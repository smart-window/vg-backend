defmodule VelocityWeb.Controllers.OktaControllerTest do
  use VelocityWeb.ConnCase, async: true

  import Mox

  alias Velocity.Repo
  alias Velocity.Schema.User

  @okta_user_uid "00u59ouv7dPrcrzHe357"
  @okta_group_slug "csr"
  @role_slug "employee-reporting"

  @create_user_params %{
    "data" => %{
      "events" => [
        %{
          "uuid" => "5b899edc-e75a-11ea-a466-a5824f6702ff",
          "published" => "2020-08-26T05:09:45.704Z",
          "eventType" => "user.lifecycle.create",
          "target" => [
            %{
              "id" => @okta_user_uid,
              "type" => "User",
              "alternateId" => "bobby@gmail.com",
              "displayName" => "bobby porter"
            },
            %{
              "alternateId" => "unknown",
              "displayName" => "csr",
              "id" => "00g2xq7t8n1wDjKKM357",
              "type" => "UserGroup"
            },
            %{
              "alternateId" => "unknown",
              "displayName" => "PegaAdmins",
              "id" => "00g2xq7t8n1wDjKKM357",
              "type" => "UserGroup"
            }
          ]
        }
      ]
    }
  }

  @delete_user_params %{
    "data" => %{
      "events" => [
        %{
          "uuid" => "3bf2cf67-e75b-11ea-b036-130d639f6c97",
          "published" => "2020-08-26T05:16:02.203Z",
          "eventType" => "user.lifecycle.delete.initiated",
          "target" => [
            %{
              "id" => @okta_user_uid,
              "type" => "User",
              "alternateId" => "sethgordonw+1@gmail.com",
              "displayName" => "Seth1 Weinheimer"
            }
          ]
        }
      ]
    }
  }

  @assign_group_params %{
    "data" => %{
      "events" => [
        %{
          "uuid" => "6ac903a3-e8e3-11ea-8202-67519ec196f2",
          "published" => "2020-08-28T04:03:23.500Z",
          "eventType" => "group.user_membership.add",
          "target" => [
            %{
              "id" => @okta_user_uid,
              "type" => "User",
              "alternateId" => "bobby@gmail.com",
              "displayName" => "bobby porter"
            },
            %{
              "id" => "00g35r9xbpzuX0aNA357",
              "type" => "UserGroup",
              "alternateId" => "unknown",
              "displayName" => @okta_group_slug
            }
          ]
        }
      ]
    }
  }

  @remove_group_params %{
    "data" => %{
      "events" => [
        %{
          "uuid" => "80b7f143-e8e3-11ea-89f2-29200be64956",
          "published" => "2020-08-28T04:04:00.298Z",
          "eventType" => "group.user_membership.remove",
          "target" => [
            %{
              "id" => @okta_user_uid,
              "type" => "User",
              "alternateId" => "bobby@gmail.com",
              "displayName" => "bobby porter"
            },
            %{
              "id" => "00g35r9xbpzuX0aNA357",
              "type" => "UserGroup",
              "alternateId" => "unknown",
              "displayName" => @okta_group_slug
            }
          ]
        }
      ]
    }
  }

  describe "POST /okta/events" do
    test "(user.lifecycle.create) it creates the user", %{conn: conn} do
      conn = post(conn, Routes.okta_path(conn, :received), @create_user_params)

      assert json_response(conn, 200)
      assert User |> Repo.all() |> length() == 1
    end

    test "(user.lifecycle.create) it can be called twice", %{conn: conn} do
      conn = post(conn, Routes.okta_path(conn, :received), @create_user_params)
      post(Phoenix.ConnTest.build_conn(), Routes.okta_path(conn, :received), @create_user_params)

      assert json_response(conn, 200)
      assert User |> Repo.all() |> length() == 1
    end

    test "(user.lifecycle.create) it adds the user to any matching 'groups'", %{conn: conn} do
      group = Factory.insert(:group, %{slug: @okta_group_slug, okta_group_slug: @okta_group_slug})
      _role = Factory.insert(:role, %{slug: @role_slug})
      group2 = Factory.insert(:group, %{slug: "pega_admins", okta_group_slug: "PegaAdmins"})

      conn = post(conn, Routes.okta_path(conn, :received), @create_user_params)

      assert json_response(conn, 200)
      assert user = Repo.one(User)
      with_groups = Repo.preload(user, :groups)
      assert Enum.find(with_groups.groups, &(&1.id == group.id))
      assert Enum.find(with_groups.groups, &(&1.id == group2.id))
    end

    test "(user.lifecycle.delete.initiated) it deletes the user", %{conn: conn} do
      Factory.insert(:user, %{okta_user_uid: @okta_user_uid})
      conn = post(conn, Routes.okta_path(conn, :received), @delete_user_params)

      assert json_response(conn, 200)
      assert User |> Repo.all() |> length() == 0
    end

    test "(user.lifecycle.delete.initiated) it can be called twice", %{conn: conn} do
      Factory.insert(:user, %{okta_user_uid: @okta_user_uid})
      conn = post(conn, Routes.okta_path(conn, :received), @delete_user_params)
      post(Phoenix.ConnTest.build_conn(), Routes.okta_path(conn, :received), @delete_user_params)

      assert json_response(conn, 200)
      assert User |> Repo.all() |> length() == 0
    end

    test "(group.user_membership.add) it assigns the matching group from the user", %{conn: conn} do
      user = Factory.insert(:user, %{okta_user_uid: @okta_user_uid})
      Factory.insert(:group, %{slug: @okta_group_slug, okta_group_slug: @okta_group_slug})
      Factory.insert(:role, %{slug: @role_slug})

      conn = post(conn, Routes.okta_path(conn, :received), @assign_group_params)

      reload_user = Repo.get(User, user.id) |> Repo.preload(:groups)

      assert json_response(conn, 200)
      assert Enum.find(reload_user.groups, &(&1.slug == @okta_group_slug))
    end

    test "(group.user_membership.add) it can be called twice", %{conn: conn} do
      user = Factory.insert(:user, %{okta_user_uid: @okta_user_uid})

      Factory.insert(:group, %{slug: @okta_group_slug, okta_group_slug: @okta_group_slug})
      Factory.insert(:role, %{slug: @role_slug})

      conn = post(conn, Routes.okta_path(conn, :received), @assign_group_params)
      post(Phoenix.ConnTest.build_conn(), Routes.okta_path(conn, :received), @assign_group_params)

      reload_user = Repo.get(User, user.id) |> Repo.preload(:groups)

      assert json_response(conn, 200)
      assert Enum.find(reload_user.groups, &(&1.slug == @okta_group_slug))
    end

    test "(group.user_membership.add) it adds correct user_roles for group->role mapping", %{
      conn: conn
    } do
      user = Factory.insert(:user, %{okta_user_uid: @okta_user_uid})

      Factory.insert(:group, %{slug: @okta_group_slug, okta_group_slug: @okta_group_slug})
      Factory.insert(:role, %{slug: @role_slug})

      conn = post(conn, Routes.okta_path(conn, :received), @assign_group_params)
      post(Phoenix.ConnTest.build_conn(), Routes.okta_path(conn, :received), @assign_group_params)

      reload_user = Repo.get(User, user.id) |> Repo.preload(:roles)

      assert json_response(conn, 200)
      assert Enum.find(reload_user.roles, &(&1.slug == @role_slug))
    end

    test "(group.user_membership.remove) it removes the matching group from the user", %{
      conn: conn
    } do
      user = Factory.insert(:user, %{okta_user_uid: @okta_user_uid})
      group = Factory.insert(:group, %{slug: @okta_group_slug, okta_group_slug: @okta_group_slug})
      Factory.insert(:role, %{slug: @role_slug})
      Factory.insert(:user_group, %{user_id: user.id, group_id: group.id})

      conn = post(conn, Routes.okta_path(conn, :received), @remove_group_params)

      reload_user = Repo.get(User, user.id) |> Repo.preload(:groups)

      assert json_response(conn, 200)
      refute Enum.find(reload_user.groups, &(&1.slug == @okta_group_slug))
    end

    test "(group.user_membership.remove) it removes corresponding roles for matching group from the user",
         %{
           conn: conn
         } do
      user = Factory.insert(:user, %{okta_user_uid: @okta_user_uid})
      group = Factory.insert(:group, %{slug: @okta_group_slug, okta_group_slug: @okta_group_slug})
      role = Factory.insert(:role, %{slug: @role_slug})
      Factory.insert(:user_group, %{user_id: user.id, group_id: group.id})
      Factory.insert(:user_role, %{user_id: user.id, role_id: role.id})

      conn = post(conn, Routes.okta_path(conn, :received), @remove_group_params)

      reload_user = Repo.get(User, user.id) |> Repo.preload(:roles)

      assert json_response(conn, 200)
      refute Enum.find(reload_user.roles, &(&1.slug == @role_slug))
    end

    test "(group.user_membership.remove) it can be called twice", %{
      conn: conn
    } do
      user = Factory.insert(:user, %{okta_user_uid: @okta_user_uid})
      group = Factory.insert(:group, %{slug: @okta_group_slug, okta_group_slug: @okta_group_slug})
      Factory.insert(:role, %{slug: @role_slug})
      Factory.insert(:user_group, %{user_id: user.id, group_id: group.id})

      conn = post(conn, Routes.okta_path(conn, :received), @remove_group_params)

      reload_user = Repo.get(User, user.id) |> Repo.preload(:groups)

      assert json_response(conn, 200)
      refute Enum.find(reload_user.groups, &(&1.slug == @okta_group_slug))
    end
  end

  describe "GET /okta/events/*" do
    test "it returns the verification challenge on all routes", %{conn: conn} do
      challenge_answer = "dingo"
      conn = put_req_header(conn, "x-okta-verification-challenge", challenge_answer)

      verified_conn = get(conn, Routes.okta_path(conn, :received))

      assert %{"verification" => ^challenge_answer} = json_response(verified_conn, 200)
    end
  end

  describe "GET /user_check" do
    test "it returns a 200 response with a message", %{conn: conn} do
      Velocity.Clients.MockOkta
      |> expect(:get_user, fn _username ->
        {:ok,
         %{
           status: 200,
           body: %{
             "id" => "12345",
             "status" => "ACTIVE"
           }
         }}
      end)
      |> expect(:reset_password, fn _id ->
        {:ok,
         %{
           status: 200
         }}
      end)

      response =
        conn
        |> get(Routes.okta_path(conn, :user_check) <> "?username=bob@gmail.com")
        |> json_response(200)

      assert response["message"]
    end
  end
end
