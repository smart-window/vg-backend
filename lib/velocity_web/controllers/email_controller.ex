defmodule VelocityWeb.EmailController do
  use VelocityWeb, :controller

  plug :put_layout, "email.html"

  def render_template(conn, %{"template" => template}) do
    render(conn, "#{template}.html")
  end
end
