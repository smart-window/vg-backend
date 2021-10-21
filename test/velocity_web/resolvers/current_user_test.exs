defmodule VelocityWeb.Resolvers.CurrentUserTest do
  use VelocityWeb.ConnCase, async: true

  @current_user_query """
    query {
      currentUser {
        id
        firstName
        lastName
        birthDate
        nationality {
          id
          iso_alpha_2_code
        }
      }
    }
  """

  @change_user_language_query """
    mutation ChangeUserLanguage($language: String!) {
      changeUserLanguage(language: $language) {
        id
        firstName
        lastName
        birthDate
        settings {
          language
        }
      }
    }
  """

  @set_client_state_query """
    mutation SetClientState($clientState: Json!) {
      setClientState(clientState: $clientState) {
        id
        firstName
        lastName
        clientState
      }
    }
  """

  describe "query :current_user query" do
    test "it returns the current user", %{conn: conn} do
      user = Factory.insert(:user, %{nationality: %{name: "America", iso_alpha_2_code: "US"}})

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @current_user_query
        })
        |> json_response(200)

      assert %{"data" => %{"currentUser" => %{"firstName" => first_name}}} = response
      assert user.first_name == first_name
    end
  end

  describe "mutation :change_user_language query" do
    test "it changes the current user's language", %{conn: conn} do
      user = Factory.insert(:user)

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @change_user_language_query,
          variables: %{
            language: "es"
          }
        })
        |> json_response(200)

      assert %{"data" => %{"changeUserLanguage" => %{"settings" => %{"language" => "es"}}}} =
               response
    end
  end

  describe "mutation :set_client_state query" do
    test "it updates the current user's client_state", %{conn: conn} do
      user = Factory.insert(:user)

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @set_client_state_query,
          variables: %{
            clientState: "{\"foo\": \"bar\"}"
          }
        })
        |> json_response(200)

      assert %{"data" => %{"setClientState" => %{"clientState" => %{"foo" => "bar"}}}} = response
    end
  end
end
