# Inspired by https://github.com/taher435/looker_embed_sso_examples/blob/master/elixir/elixir_example.exs
defmodule VelocityWeb.Controllers.LookerController do
  @moduledoc """
    Controller for the client app to interface with Looker dashboards.
  """
  use VelocityWeb, :controller

  @doc """
    Returns a one-time Looker dashboard URL from a Restful POST.
    Response format: {"looker_url": generated_url}
    ## Parameters
      - conn: Phoenix http connection.
  """
  def sso_embed_url(conn, _params) do
    {:ok, embed_url} = get_embed_url()

    conn
    |> put_status(200)
    |> json(%{looker_url: embed_url})
  end

  defp wrap_quotes(value), do: "\"#{value}\""

  # Helper for sso_embed_url.
  # Currently using hard-coded values for our demo Looker environment (dummy data).
  defp get_embed_url do
    fifteen_minutes = 15 * 60

    url_data = %{
      host: "velocityembed.cloud.looker.com",
      secret: Application.get_env(:velocity, :looker_sso_secret),
      external_user_id: 7 |> wrap_quotes,
      first_name: "Embed" |> wrap_quotes,
      last_name: "Test" |> wrap_quotes,
      group_ids: [3],
      external_group_id: "awesome_engineers" |> wrap_quotes,
      permissions: [],
      models: [],
      access_filters: %{},
      user_attributes: %{},
      session_length: fifteen_minutes |> to_string,
      embed_url:
        "/embed/looks/2?embed_domain=" <> Application.get_env(:velocity, :looker_embed_domain),
      force_logout_login: true
    }

    # looker options
    secret = url_data[:secret]
    host = url_data[:host]

    # map/list user options, explicitly encoded to JSON
    json_permissions = Jason.encode!(url_data[:permissions])
    json_models = Jason.encode!(url_data[:models])
    json_group_ids = Jason.encode!(url_data[:group_ids])
    json_user_attributes = Jason.encode!(%{})
    json_access_filters = Jason.encode!(%{})

    # url/session specific options
    embed_path = "/login/embed/" <> URI.encode_www_form(url_data[:embed_url])

    # computed options
    time = DateTime.utc_now() |> DateTime.to_unix() |> to_string

    # This can be any value of our choosing, so long as it doesn't repeat within an hour.
    json_nonce =
      :crypto.strong_rand_bytes(16)
      |> Base.encode16(padding: false)
      |> Jason.encode!()

    # compute signature - the order of fields matters greatly
    string_to_sign =
      "" <>
        host <>
        "\n" <>
        embed_path <>
        "\n" <>
        json_nonce <>
        "\n" <>
        time <>
        "\n" <>
        url_data[:session_length] <>
        "\n" <>
        url_data[:external_user_id] <>
        "\n" <>
        json_permissions <>
        "\n" <>
        json_models <> "\n"

    string_to_sign =
      if is_nil(url_data[:group_ids]) do
        string_to_sign
      else
        string_to_sign <> json_group_ids <> "\n"
      end

    string_to_sign =
      if is_nil(url_data[:external_group_id]) do
        string_to_sign
      else
        string_to_sign <> url_data[:external_group_id] <> "\n"
      end

    string_to_sign = string_to_sign <> json_user_attributes <> "\n"
    string_to_sign = string_to_sign <> json_access_filters

    signature =
      :crypto.hmac(:sha, secret, string_to_sign)
      |> Base.encode64()

    # construct query string
    query_string =
      %{
        nonce: json_nonce,
        time: time,
        session_length: url_data[:session_length],
        external_user_id: url_data[:external_user_id],
        permissions: json_permissions,
        models: json_models,
        access_filters: json_access_filters,
        first_name: url_data[:first_name],
        last_name: url_data[:last_name],
        signature: signature,
        group_ids: json_group_ids,
        external_group_id: url_data[:external_group_id],
        user_attributes: json_user_attributes,
        force_logout_login: url_data[:force_logout_login]
      }
      |> URI.encode_query()

    embed_url = "https://" <> host <> embed_path <> "?" <> query_string
    {:ok, embed_url}
  end
end
