defmodule Velocity.Contexts.OktaTest do
  use Velocity.DataCase, async: true

  import Mox

  alias Velocity.Contexts.Okta
  alias Velocity.Schema.User
  alias Velocity.Schema.UserGroup

  setup :verify_on_exit!

  describe "sync_okta_users/0" do
    test "it inserts a user and adds them to the group" do
      group = Factory.insert(:group, %{slug: "slug", okta_group_slug: "CSR"})

      Velocity.Clients.MockOkta
      |> expect(:list_active_users, fn _cursor ->
        {:ok,
         %{
           headers: [{"x-rate-limit-remaining", "100"}],
           body: [
             %{
               "id" => "o12345",
               "profile" => %{
                 "firstName" => "bob",
                 "lastName" => "bones",
                 "email" => "b@g.co"
               }
             }
           ]
         }}
      end)
      |> expect(:get_user_groups, fn _okta_user_uid ->
        {:ok,
         %{
           headers: [{"x-rate-limit-remaining", "100"}],
           body: [
             %{
               "profile" => %{
                 "name" => "CSR"
               }
             }
           ]
         }}
      end)

      Okta.sync_okta_users()

      assert user = Repo.one(User)
      assert user_group = Repo.one(UserGroup)
      assert user_group.user_id == user.id
      assert user_group.group_id == group.id
    end

    test "it upserts to the okta_uid" do
      Factory.insert(:user, %{okta_user_uid: "o12345"})
      group = Factory.insert(:group, %{slug: "slug", okta_group_slug: "CSR"})

      Velocity.Clients.MockOkta
      |> expect(:list_active_users, fn _cursor ->
        {:ok,
         %{
           headers: [{"x-rate-limit-remaining", "100"}],
           body: [
             %{
               "id" => "o12345",
               "profile" => %{
                 "firstName" => "bob",
                 "lastName" => "bones",
                 "email" => "b@g.co"
               }
             }
           ]
         }}
      end)
      |> expect(:get_user_groups, fn _okta_user_uid ->
        {:ok,
         %{
           headers: [{"x-rate-limit-remaining", "100"}],
           body: [
             %{
               "profile" => %{
                 "name" => "CSR"
               }
             }
           ]
         }}
      end)

      Okta.sync_okta_users()

      assert user = Repo.one(User)
      assert user_group = Repo.one(UserGroup)
      assert user_group.user_id == user.id
      assert user_group.group_id == group.id
    end

    test "it adds a new group to an existing user" do
      Factory.insert(:user, %{okta_user_uid: "morganfreeman"})
      group = Factory.insert(:group, %{slug: "customers", okta_group_slug: "Customers"})

      Velocity.Clients.MockOkta
      |> expect(:list_active_users, fn _cursor ->
        {:ok,
         %{
           headers: [{"x-rate-limit-remaining", "100"}],
           body: [
             %{
               "id" => "morganfreeman",
               "profile" => %{
                 "firstName" => "bob",
                 "lastName" => "bones",
                 "email" => "b@g.co"
               }
             }
           ]
         }}
      end)
      |> expect(:get_user_groups, fn _okta_user_uid ->
        {:ok,
         %{
           headers: [{"x-rate-limit-remaining", "100"}],
           body: [
             %{
               "profile" => %{
                 "name" => "Customers"
               }
             }
           ]
         }}
      end)

      Okta.sync_okta_users()

      assert user = Repo.one(User)
      assert user_group = Repo.one(UserGroup)
      assert user_group.user_id == user.id
      assert user_group.group_id == group.id
    end

    test "it adds corresponding UserRoles for an existing user and group" do
      user = Factory.insert(:user, %{okta_user_uid: "morganfreeman"})
      Factory.insert(:group, %{slug: "csr", okta_group_slug: "CSR"})
      Factory.insert(:role, %{slug: "employee-reporting"})

      Velocity.Clients.MockOkta
      |> expect(:list_active_users, fn _cursor ->
        {:ok,
         %{
           headers: [{"x-rate-limit-remaining", "100"}],
           body: [
             %{
               "id" => "morganfreeman",
               "profile" => %{
                 "firstName" => "bob",
                 "lastName" => "bones",
                 "email" => "b@g.co"
               }
             }
           ]
         }}
      end)
      |> expect(:get_user_groups, fn _okta_user_uid ->
        {:ok,
         %{
           headers: [{"x-rate-limit-remaining", "100"}],
           body: [
             %{
               "profile" => %{
                 "name" => "CSR"
               }
             }
           ]
         }}
      end)

      Okta.sync_okta_users()

      reload_user = Repo.get(User, user.id) |> Repo.preload(:roles)
      assert Enum.find(reload_user.roles, &(&1.slug == "employee-reporting"))
    end
  end
end
