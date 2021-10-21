defmodule VelocityWeb.Resolvers.CurrentUser do
  @moduledoc """
  GQL resolver for current_user
  """

  alias Velocity.Contexts.Users
  alias Velocity.Repo

  def get(_args, %{context: %{current_user: current_user}}) do
    current_user_with_nationality = Repo.preload(current_user, :nationality)

    {:ok, AtomicMap.convert(current_user_with_nationality, safe: false)}
  end

  def change_user_language(args, %{context: %{current_user: current_user}}) do
    Users.change_user_language(current_user, args.language)
  end

  def set_client_state(args, %{context: %{current_user: current_user}}) do
    user = Users.update!(current_user, %{"client_state" => args.client_state})
    {:ok, user}
  end
end
