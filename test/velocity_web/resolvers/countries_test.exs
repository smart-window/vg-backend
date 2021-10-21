defmodule VelocityWeb.Resolvers.CountriesTest do
  use VelocityWeb.ConnCase, async: true

  @all_countries_query """
    query {
      countries {
        id
        name
      }
    }
  """

  describe "query :all_countries query" do
    test "it returns a list of all countries", %{conn: conn} do
      user = Factory.insert(:user)

      mock_country =
        Factory.insert(:country, %{name: "United States", iso_alpha_2_code: "US", id: 1})

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @all_countries_query
        })
        |> json_response(200)

      assert %{"data" => %{"countries" => [%{"name" => country_name}]}} = response
      assert mock_country.name == country_name
    end
  end
end
