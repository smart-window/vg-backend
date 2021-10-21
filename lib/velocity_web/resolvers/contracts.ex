defmodule VelocityWeb.Resolvers.Contracts do
  @moduledoc """
  GQL resolver for jobs
  """

  alias Velocity.Contexts.Contracts
  alias Velocity.Contexts.Users
  alias Velocity.Repo
  alias Velocity.Schema.Employment

  import Ecto.Query

  def get(args, %{context: %{current_user: current_user}}) do
    employment =
      Repo.one!(
        from(e in Employment,
          join: em in assoc(e, :employee),
          where: e.contract_id == ^String.to_integer(args.id) and em.user_id == ^current_user.id
        )
      )

    if Users.is_user_internal(current_user) || !is_nil(employment) do
      {:ok, Contracts.get!(String.to_integer(args.id))}
    else
      {:error, "User #{current_user.id} is not authorized to get contract #{args.id}"}
    end
  end

  def get_for_client(args, _) do
    {:ok, Contracts.get_for_client(String.to_integer(args.client_id))}
  end

  def create(args, %{context: %{current_user: current_user}}) do
    if Users.is_user_internal(current_user) do
      Contracts.create(args)
    else
      {:error, "User #{current_user.id} is not authorized to create a contract"}
    end
  end

  def update(args, %{context: %{current_user: current_user}}) do
    if Users.is_user_internal(current_user) do
      Contracts.update(args)
    else
      {:error, "User #{current_user.id} is not authorized to edit contract #{args.id}"}
    end
  end

  def delete(args, %{context: %{current_user: current_user}}) do
    if Users.is_user_internal(current_user) do
      Contracts.delete(String.to_integer(args.id))
    else
      {:error, "User #{current_user.id} is not authorized to delete contract #{args.id}"}
    end
  end

  def paginated_client_contracts_report(args, _) do
    client_contract_report_items =
      Contracts.paginated_client_contracts_report(
        args.page_size,
        String.to_atom(Macro.underscore(args.sort_column)),
        String.to_atom(args.sort_direction),
        args.last_id,
        args.last_value,
        args.filter_by,
        args.search_by
      )

    row_count =
      if Enum.count(client_contract_report_items) > 0 do
        Enum.at(client_contract_report_items, 0)[:sql_row_count]
      else
        0
      end

    {:ok, %{row_count: row_count, client_contract_report_items: client_contract_report_items}}
  end
end
