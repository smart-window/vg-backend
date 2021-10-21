defmodule VelocityWeb.Resolvers.Clients do
  @moduledoc """
    resolver for clients
  """

  alias Velocity.Contexts.Clients

  def all(_args, _) do
    {:ok, Clients.list_clients()}
  end

  def get(args, _) do
    {:ok, Clients.get_client!(args.id)}
  end

  def get_for_name(args, _) do
    {:ok, Clients.get_client_for_name(args.name)}
  end

  def create_client(args, _) do
    Clients.create_client(args)
  end

  def update_client(args, _) do
    Clients.update_client(args)
  end

  def get_teams(args, _) do
    teams = Clients.get_teams(args.client_id)
    {:ok, teams}
  end

  def update_client_general(args, _) do
    Clients.update_client_general(args)
  end

  def update_client_goals(args, _) do
    Clients.update_client_goals(args)
  end

  def update_client_interaction_notes(args, _) do
    Clients.update_client_interaction_notes(args)
  end

  def update_client_referral_information(args, _) do
    Clients.update_client_referral_information(args)
  end

  def update_client_payments_and_pricing(args, _) do
    Clients.update_client_payments_and_pricing(args)
  end

  def paginated_clients_report(args, _) do
    client_report_items =
      Clients.paginated_clients_report(
        args.page_size,
        String.to_atom(Macro.underscore(args.sort_column)),
        String.to_atom(args.sort_direction),
        args.last_id,
        args.last_value,
        args.filter_by,
        args.search_by
      )

    row_count =
      if Enum.count(client_report_items) > 0 do
        Enum.at(client_report_items, 0)[:sql_row_count]
      else
        0
      end

    {:ok, %{row_count: row_count, client_report_items: client_report_items}}
  end
end
