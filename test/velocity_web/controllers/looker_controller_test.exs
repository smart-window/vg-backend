defmodule VelocityWeb.Controllers.LookerControllerTest do
  use VelocityWeb.ConnCase, async: true

  describe "POST /looker/sso_embed_url" do
    test "it works", %{conn: conn} do
      user = Factory.insert(:user)

      %{"looker_url" => looker_url} =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post(Routes.looker_path(conn, :sso_embed_url), %{okta_user_uid: "hi"})
        |> json_response(200)

      parsed_uri = URI.parse(looker_url)
      parsed_query = URI.decode_query(parsed_uri.query)

      assert parsed_uri.scheme == "https"
      assert parsed_uri.host == "velocityembed.cloud.looker.com"
      assert parsed_query["nonce"]
      assert parsed_query["signature"]
    end
  end
end
