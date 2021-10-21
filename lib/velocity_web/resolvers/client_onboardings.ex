defmodule VelocityWeb.Resolvers.ClientOnboardings do
  @moduledoc """
  GQL resolver for client onboardings
  """

  alias Velocity.Contexts.ClientOnboardings

  def get(args, %{context: %{current_user: current_user}}) do
    {:ok, ClientOnboardings.get!(current_user.id, String.to_integer(args.id))}
  end

  def get_for_contract(args, %{context: %{current_user: current_user}}) do
    {:ok,
     ClientOnboardings.get_for_contract(current_user.id, String.to_integer(args.contract_id))}
  end

  def create(args, _) do
    ClientOnboardings.create(args)
  end

  def start(args, _) do
    ClientOnboardings.start(args)
  end

  def update(args, _) do
    ClientOnboardings.update(args)
  end

  def delete(args, _) do
    ClientOnboardings.delete(String.to_integer(args.id))
  end

  def client_onboardings(args, _) do
    client_onboardings =
      ClientOnboardings.client_onboardings_report(
        args.page_size,
        String.to_atom(Macro.underscore(args.sort_column)),
        String.to_atom(args.sort_direction),
        args.last_id,
        args.last_value,
        args.filter_by,
        args.search_by
      )

    row_count =
      if Enum.count(client_onboardings) > 0 do
        Enum.at(client_onboardings, 0)[:sql_row_count]
      else
        0
      end

    {:ok, %{row_count: row_count, client_onboardings: client_onboardings}}
  end
end
