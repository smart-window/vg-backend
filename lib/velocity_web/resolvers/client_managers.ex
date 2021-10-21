defmodule VelocityWeb.Resolvers.ClientManagers do
  @moduledoc """
  GQL resolver for client managers
  """

  alias Velocity.Contexts.ClientManagers
  alias Velocity.Contexts.Users

  def all(_args, _) do
    {:ok, ClientManagers.all()}
  end

  def get(args, _) do
    {:ok, ClientManagers.get!(String.to_integer(args.id))}
  end

  def create(args, _) do
    # okta_user_uid is a random string until we have a clear workflow of how to create a new user login
    okta_user_uid = for _ <- 1..10, into: "", do: <<Enum.random('0123456789abcdef')>>

    {:ok, user} =
      Users.create(%{
        first_name: args.first_name,
        last_name: args[:last_name],
        email: args.email,
        okta_user_uid: okta_user_uid
      })

    ClientManagers.create(%{
      user_id: user.id,
      client_id: args.client_id,
      job_title: args[:job_title],
      email: args[:email],
      reports_to_id: args[:reports_to_id]
    })
  end

  def delete(args, _) do
    ClientManagers.delete(String.to_integer(args.id))
  end

  def paginated_client_managers_report(args, _) do
    client_manager_report_items =
      ClientManagers.paginated_client_managers_report(
        args.page_size,
        String.to_atom(Macro.underscore(args.sort_column)),
        String.to_atom(args.sort_direction),
        args.last_id,
        args.last_value,
        args.filter_by,
        args.search_by
      )

    row_count =
      if Enum.count(client_manager_report_items) > 0 do
        Enum.at(client_manager_report_items, 0)[:sql_row_count]
      else
        0
      end

    {:ok, %{row_count: row_count, client_manager_report_items: client_manager_report_items}}
  end

  def update_client_manager(args, _) do
    ClientManagers.update_client_manager(args)
  end
end
