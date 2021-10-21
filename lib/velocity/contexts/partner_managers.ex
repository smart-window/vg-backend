defmodule Velocity.Contexts.PartnerManagers do
  @moduledoc """
  The Contexts.PartnerManagers context.
  """
  alias Ecto.Query

  alias Velocity.Repo
  alias Velocity.Schema.Address
  alias Velocity.Schema.Country
  alias Velocity.Schema.Partner
  alias Velocity.Schema.PartnerManager
  alias Velocity.Schema.Region
  alias Velocity.Schema.User
  alias Velocity.Schema.PartnerContact

  import Ecto.Query

  @doc """
  Returns the list of partner_managers.

  ## Examples

      iex> list_partner_managers()
      [%PartnerManager{}, ...]

  """
  def list_partner_managers do
    Repo.all(PartnerManager)
    |> Repo.preload([:partner, :user])
  end

  def get!(id) do
    Repo.get!(PartnerManager, id)
  end

  @doc """
  Gets a single partner_manager.

  Raises if the Partner manager does not exist.

  ## Examples

      iex> get_partner_manager!(123)
      %PartnerManager{}

  """
  def get_partner_manager!(id),
    do: Repo.get!(PartnerManager, id) |> Repo.preload([:partner, :user])

  @doc """
  Creates a partner_manager.

  ## Examples

      iex> create_partner_manager(%{field: value})
      {:ok, %PartnerManager{}}

      iex> create_partner_manager(%{field: bad_value})
      {:error, ...}

  """
  def create_partner_manager(attrs \\ %{}) do
    %PartnerManager{}
    |> PartnerManager.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a partner_manager.

  ## Examples

      iex> update_partner_manager(partner_manager, %{field: new_value})
      {:ok, %PartnerManager{}}

      iex> update_partner_manager(partner_manager, %{field: bad_value})
      {:error, ...}

  """
  def update_partner_manager(id, attrs) do
    Repo.get!(PartnerManager, id)
    |> PartnerManager.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a PartnerManager.

  ## Examples

      iex> delete_partner_manager(partner_manager)
      {:ok, %PartnerManager{}}

      iex> delete_partner_manager(partner_manager)
      {:error, ...}

  """
  def delete_partner_manager(id) do
    %PartnerManager{id: id}
    |> Repo.delete()
  end

  def paginated_partner_managers_report(
        page_size,
        sort_column,
        sort_direction,
        last_id,
        last_value,
        filter_by,
        search_by
      ) do
    query =
      partner_managers_report_query(
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

  defp partner_managers_report_query(
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

    from(partner_manager in PartnerManager,
      as: :partner_manager,
      left_join: user in User,
      as: :user,
      on: user.id == partner_manager.user_id,
      left_join: partner in Partner,
      as: :partner,
      on: partner.id == partner_manager.partner_id,
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
        id: partner_manager.id,
        name: user.full_name,
        partner_name: partner.name,
        region_name: region.name,
        country_name: country.name,
        job_title: partner_manager.job_title,
        sql_row_count: fragment("count(*) over()")
      }
    )
  end

  defp build_last_record_clause(0, _last_value, _sort_column, _sort_direction) do
    dynamic(true)
  end

  defp build_last_record_clause(last_id, last_value, sort_column, sort_direction) do
    cond do
      Enum.member?([:partner_name], sort_column) ->
        last_record_clause(sort_direction, :partner_manager, :partner, :name, last_id, last_value)

      Enum.member?([:region_name], sort_column) ->
        last_record_clause(sort_direction, :partner_manager, :region, :name, last_id, last_value)
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

  defp build_order_by_clause(:partner_name, sort_direction) do
    [{sort_direction, dynamic([partner: p], p.name)}, asc: :id]
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

  defp build_filter_where_clause("partner_id", value) do
    partner_ids = String.split(value, ",")
    dynamic([partner: p], p.id in ^partner_ids)
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

  def update_partner_manager(args) do
    partner_manager = Repo.get_by!(PartnerManager, %{id: args.id})

    user = Repo.get_by!(User, %{id: partner_manager.user_id})

    Repo.get!(User, user.id)
    |> User.changeset(args)
    |> Repo.update()

    if Map.has_key?(args, :partner_id) do
      Repo.delete_all(
        from(cc in PartnerContact,
          join: pm in PartnerManager,
          on: cc.user_id == pm.user_id,
          where: pm.id == ^args.id and cc.partner_id == ^partner_manager.partner_id
        )
      )
    end

    partner_manager
    |> PartnerManager.changeset(args)
    |> Repo.update()
  end
end
