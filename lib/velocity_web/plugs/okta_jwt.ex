defmodule VelocityWeb.Plugs.OktaJwt do
  import Plug.Conn

  alias VelocityWeb.HttpClients.Http
  require Logger

  def init(options), do: options

  def call(conn, _opts) do
    jwt_token =
      if Map.has_key?(conn.params, :token) do
        conn.params[:token]
        |> String.split(" ")
        |> List.last()
      else
        conn
        |> get_req_header("authorization")
        |> List.first()
        |> String.split(" ")
        |> List.last()
      end

    case verify_and_validate_jwt(jwt_token) do
      {:ok, claims} ->
        uid = claims["uid"] || claims["sub"]
        assign(conn, :current_user_okta_uid, uid)

      {:error, error} ->
        Logger.error("OktaJwt verify error: #{inspect(error)}")
        render_unauthorized(conn)
    end
  rescue
    error ->
      Logger.error(Exception.format(:error, error, __STACKTRACE__))
      render_unauthorized(conn)
  end

  def verify_and_validate_jwt(jwt) do
    {:ok, %{"iss" => issuer, "aud" => aud}} = Joken.peek_claims(jwt)
    {:ok, %{"kid" => kid}} = Joken.peek_header(jwt)

    issuer_client = Http.client(issuer)

    {:ok, %{body: %{"jwks_uri" => jwks_uri}}} =
      Tesla.get(
        issuer_client,
        "/.well-known/oauth-authorization-server?client_id=#{aud}"
      )

    {:ok, %{body: %{"keys" => keys}}} = Tesla.get(issuer_client, jwks_uri)

    jwk = Enum.find(keys, &(&1["kid"] == kid))
    signer = Joken.Signer.create(jwk["alg"], jwk)

    token_config = %{
      "cid" => %Joken.Claim{
        validate: fn val, _claims, _context ->
          val &&
            val in [
              Application.get_env(:velocity, :okta_client_id),
              Application.get_env(:velocity, :okta_mobile_client_id)
            ]
        end
      },
      "iss" => %Joken.Claim{
        validate: fn val, _claims, _context ->
          val && val == Application.get_env(:velocity, :okta_issuer)
        end
      },
      "exp" => %Joken.Claim{
        validate: fn val, _claims, _context ->
          val && val > DateTime.utc_now() |> DateTime.to_unix()
        end
      }
    }

    Joken.verify_and_validate(token_config, jwt, signer)
  end

  defp render_unauthorized(conn) do
    conn
    |> put_status(:unauthorized)
    |> put_resp_header("content-type", "application/json")
    |> halt()
    |> send_resp(:unauthorized, Jason.encode!(%{message: :unauthorized}))
  end

  defmodule Mock do
    @moduledoc """
      mock of OktaJwt for use in test.  This module does not perform any auth.  It allows the tests to set the current user.
    """
    def init(opts), do: opts

    def call(conn, _) do
      okta_user_uid = conn |> get_req_header("test-only-okta-user-uid") |> List.first()
      assign(conn, :current_user_okta_uid, okta_user_uid)
    end
  end
end
