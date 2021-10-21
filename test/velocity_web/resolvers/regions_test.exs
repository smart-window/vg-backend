defmodule VelocityWeb.Resolvers.RegionsTest do
  use VelocityWeb.ConnCase, async: true

  alias Velocity.Repo
  alias Velocity.Schema.Region

  @get_region_query """
    query($id: ID!) {
      region(id: $id) {
        id
        name
        countries {
          id
          iso_alpha_2_code
          name
        }
      }
    }
  """

  @create_region_mutation """
    mutation CreateRegion($name: String!) {
      createRegion(name: $name) {
        id
        name
      }
    }
  """

  @update_region_mutation """
    mutation UpdateRegion($id: ID!, $name: String!) {
      updateRegion(id: $id, name: $name ) {
        id
        name
      }
    }
  """

  @delete_region_mutation """
    mutation DeleteRegion($id: ID!) {
      deleteRegion(id: $id) {
        id
      }
    }
  """

  def setup_user do
    Factory.insert(:user, %{
      avatar_url: "http://old.url"
    })
  end

  describe "query :regions" do
    test "it gets a region", %{conn: conn} do
      user = setup_user()

      region =
        Factory.insert(:region, %{
          name: "Region One"
        })

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @get_region_query,
          variables: %{
            id: region.id
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "region" => %{
                   "id" => region_id,
                   "name" => "Region One"
                 }
               }
             } = response

      assert String.to_integer(region_id) == region.id
    end
  end

  describe "mutation :regions" do
    test "it creates a region", %{conn: conn} do
      user = setup_user()

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @create_region_mutation,
          variables: %{
            name: "Region Two"
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "createRegion" => %{
                   "id" => region_id,
                   "name" => "Region Two"
                 }
               }
             } = response

      assert Repo.get(Region, region_id)
    end

    test "it updates an existing region", %{conn: conn} do
      user = setup_user()

      region =
        Factory.insert(:region, %{
          name: "Region Three"
        })

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @update_region_mutation,
          variables: %{
            id: region.id,
            name: "Region Three Updated"
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "updateRegion" => %{
                   "id" => region_id,
                   "name" => "Region Three Updated"
                 }
               }
             } = response

      assert String.to_integer(region_id) == region.id
    end

    test "it deletes an existing region", %{conn: conn} do
      user = setup_user()

      region =
        Factory.insert(:region, %{
          name: "Region Four"
        })

      assert Repo.get(Region, region.id)

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @delete_region_mutation,
          variables: %{
            id: region.id
          }
        })
        |> json_response(200)

      assert %{"data" => %{"deleteRegion" => %{"id" => region_id}}} = response
      assert String.to_integer(region_id) == region.id
      assert Repo.get(Region, region.id) == nil
    end
  end
end
