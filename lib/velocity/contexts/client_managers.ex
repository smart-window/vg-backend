defmodule Velocity.Contexts.ClientManagers do
  @moduledoc "context for client managers"

  alias Ecto.Query
  alias Velocity.Repo
  alias Velocity.Schema.Address
  alias Velocity.Schema.Client
  alias Velocity.Schema.ClientContact
  alias Velocity.Schema.ClientManager
  alias Velocity.Schema.Country
  alias Velocity.Schema.Region
  alias Velocity.Schema.RoleAssignment
  alias Velocity.Schema.User

  import Ecto.Query

  def all do
    Repo.all(ClientManager)
  end

  def get!(id) do
    Repo.get!(ClientManager, id)
  end

  def create(params) do
    %ClientManager{}
    |> ClientManager.changeset(params)
    |> Repo.insert()
  end

  def update(params) do
    Repo.get!(ClientManager, params.id)
    |> ClientManager.changeset(params)
    |> Repo.update()
  end

  def delete(id) do
    %ClientManager{id: id}
    |> Repo.delete()
  end

  def paginated_client_managers_report(
        page_size,
        sort_column,
        sort_direction,
        last_id,
        last_value,
        filter_by,
        search_by
      ) do
    query =
      client_managers_report_query(
        sort_column,
        sort_direction,
        last_id,
        last_value,
        filter_by,
        search_by
      )

    query = Query.limit(query, ^page_size)
    Repo.all(query)
  end

  defp client_managers_report_query(
         sort_column,
         sort_direction,
         last_id,
         last_value,
         filter_by,
         search_by
       ) do
    last_record_clause =
      build_last_record_clause(last_id, last_value, sort_column, sort_direction)

    order_by_clause = build_order_by_clause(sort_column, sort_direction)
    filter_clause = build_filter_clause(filter_by)
    search_clause = build_search_clause(search_by)

    user_roles =
      from(user in User,
        left_join: roles in assoc(user, :roles),
        group_by: user.id,
        select: %{
          user_id: user.id,
          roles: fragment("string_agg(?, ?)", roles.description, ", ")
        }
      )

    from(client_manager in ClientManager,
      as: :client_manager,
      left_join: user in User,
      as: :user,
      on: user.id == client_manager.user_id,
      left_join: user_role in ^subquery(user_roles),
      as: :user_role,
      on: user_role.user_id == user.id,
      left_join: client in Client,
      as: :client,
      on: client.id == client_manager.client_id,
      left_join: address in Address,
      as: :address,
      on: user.work_address_id == address.id,
      left_join: country in Country,
      as: :country,
      on: country.id == address.country_id,
      left_join: region in Region,
      as: :region,
      on: region.id == country.region_id,
      where: ^last_record_clause,
      where: ^filter_clause,
      where: ^search_clause,
      order_by: ^order_by_clause,
      select: %{
        id: client_manager.id,
        name: user.full_name,
        job_title: client_manager.job_title,
        client_name: client.name,
        region_name: region.name,
        country_name: country.name,
        roles: user_role.roles,
        sql_row_count: fragment("count(*) over()")
      }
    )
  end

  defp build_last_record_clause(0, _last_value, _sort_column, _sort_direction) do
    dynamic(true)
  end

  defp build_last_record_clause(last_id, last_value, sort_column, sort_direction) do
    cond do
      Enum.member?([:client_name], sort_column) ->
        last_record_clause(sort_direction, :client_manager, :client, :name, last_id, last_value)

      Enum.member?([:region_name], sort_column) ->
        last_record_clause(sort_direction, :client_manager, :region, :name, last_id, last_value)
    end
  end

  defp last_record_clause(sort_direction, primary, table, sort_column, last_id, last_value) do
    if sort_direction == :asc do
      dynamic(
        [{^primary, p}, {^table, x}],
        field(x, ^sort_column) > ^last_value or
          (field(x, ^sort_column) == ^last_value and p.id > ^last_id)
      )
    else
      dynamic(
        [{^primary, p}, {^table, x}],
        field(x, ^sort_column) < ^last_value or
          (field(x, ^sort_column) == ^last_value and p.id > ^last_id)
      )
    end
  end

  defp build_order_by_clause(:name, sort_direction) do
    [{sort_direction, dynamic([user: u], u.full_name)}, asc: :id]
  end

  defp build_order_by_clause(:client_name, sort_direction) do
    [{sort_direction, dynamic([client: c], c.name)}, asc: :id]
  end

  defp build_order_by_clause(:region_name, sort_direction) do
    [{sort_direction, dynamic([region: r], r.name)}, asc: :id]
  end

  defp build_filter_clause(filter_by) do
    Enum.reduce(filter_by, dynamic(true), fn filter, filter_clause ->
      where_clause = build_filter_where_clause(Macro.underscore(filter.name), filter.value)
      dynamic([], ^filter_clause and ^where_clause)
    end)
  end

  defp build_filter_where_clause("client_id", value) do
    client_ids = String.split(value, ",")
    dynamic([client: c], c.id in ^client_ids)
  end

  defp build_filter_where_clause("country_id", value) do
    country_ids = String.split(value, ",")
    dynamic([country: cn], cn.id in ^country_ids)
  end

  defp build_search_clause(search_by) do
    if search_by != nil && String.trim(search_by) != "" do
      search_by_value = "#{String.trim(search_by)}:*"

      dynamic(
        [user: u],
        fragment("to_tsvector(?) @@ plainto_tsquery(?)", u.full_name, ^search_by_value)
      )
    else
      dynamic(true)
    end
  end

  def update_client_manager(args) do
    client_manager = Repo.get_by!(ClientManager, %{id: args.id})

    user = Repo.get_by!(User, %{id: client_manager.user_id})

    Repo.get!(User, user.id)
    |> User.changeset(args)
    |> Repo.update()

    if Map.has_key?(args, :client_id) do
      Repo.delete_all(
        from(ra in RoleAssignment,
          join: cm in ClientManager,
          on: ra.user_id == cm.user_id,
          where: cm.id == ^args.id and ra.client_id == ^client_manager.client_id
        )
      )

      Repo.delete_all(
        from(cc in ClientContact,
          join: cm in ClientManager,
          on: cc.user_id == cm.user_id,
          where: cm.id == ^args.id and cc.client_id == ^client_manager.client_id
        )
      )
    end

    client_manager
    |> ClientManager.changeset(args)
    |> Repo.update()
  end
end
