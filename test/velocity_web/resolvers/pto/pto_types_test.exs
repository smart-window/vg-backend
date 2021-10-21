defmodule VelocityWeb.Resolvers.PtoTypesTest do
  use VelocityWeb.ConnCase, async: true

  alias Velocity.Repo
  alias Velocity.Schema.Pto.PtoType

  @get_pto_type_query """
    query($id: ID!) {
      pto_type(id: $id) {
        id
        name
      }
    }
  """

  @create_pto_type_mutation """
    mutation CreatePtoType($name: String!) {
      createPtoType(name: $name) {
        id
        name
      }
    }
  """

  @update_pto_type_mutation """
    mutation UpdatePtoType($id: ID!, $name: String!) {
      updatePtoType(id: $id, name: $name ) {
        id
        name
      }
    }
  """

  @delete_pto_type_mutation """
    mutation DeletePtoType($id: ID!) {
      deletePtoType(id: $id) {
        id
      }
    }
  """

  def setup_user do
    Factory.insert(:user, %{
      avatar_url: "http://old.url"
    })
  end

  describe "query :pto_types" do
    test "it gets a pto_type", %{conn: conn} do
      user = setup_user()

      pto_type =
        Factory.insert(:pto_type, %{
          name: "PtoType One"
        })

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @get_pto_type_query,
          variables: %{
            id: pto_type.id
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "pto_type" => %{
                   "id" => pto_type_id,
                   "name" => "PtoType One"
                 }
               }
             } = response

      assert String.to_integer(pto_type_id) == pto_type.id
    end
  end

  describe "mutation :pto_types" do
    test "it creates a pto_type", %{conn: conn} do
      user = setup_user()

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @create_pto_type_mutation,
          variables: %{
            name: "PtoType Two"
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "createPtoType" => %{
                   "id" => pto_type_id,
                   "name" => "PtoType Two"
                 }
               }
             } = response

      assert Repo.get(PtoType, pto_type_id)
    end

    test "it updates an existing pto_type", %{conn: conn} do
      user = setup_user()

      pto_type =
        Factory.insert(:pto_type, %{
          name: "PtoType Three"
        })

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @update_pto_type_mutation,
          variables: %{
            id: pto_type.id,
            name: "PtoType Three Updated"
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "updatePtoType" => %{
                   "id" => pto_type_id,
                   "name" => "PtoType Three Updated"
                 }
               }
             } = response

      assert String.to_integer(pto_type_id) == pto_type.id
    end

    test "it deletes an existing pto_type", %{conn: conn} do
      user = setup_user()

      pto_type =
        Factory.insert(:pto_type, %{
          name: "PtoType Four"
        })

      assert Repo.get(PtoType, pto_type.id)

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @delete_pto_type_mutation,
          variables: %{
            id: pto_type.id
          }
        })
        |> json_response(200)

      assert %{"data" => %{"deletePtoType" => %{"id" => pto_type_id}}} = response
      assert String.to_integer(pto_type_id) == pto_type.id
      assert Repo.get(PtoType, pto_type.id) == nil
    end
  end
end
